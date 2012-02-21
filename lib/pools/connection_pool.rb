##
# This file adapted from activerecord gem
#

require 'thread'
require 'monitor'
require 'set'

module Pools
  # Raised when a connection could not be obtained within the connection
  # acquisition timeout period.
  ConnectionNotEstablished = Class.new(StandardError)
  ConnectionTimeoutError = Class.new(ConnectionNotEstablished)

  # Connection pool base class for managing Active Record database
  # connections.
  #
  # == Introduction
  #
  # A connection pool synchronizes thread access to a limited number of
  # database connections. The basic idea is that each thread checks out a
  # database connection from the pool, uses that connection, and checks the
  # connection back in. ConnectionPool is completely thread-safe, and will
  # ensure that a connection cannot be used by two threads at the same time,
  # as long as ConnectionPool's contract is correctly followed. It will also
  # handle cases in which there are more threads than connections: if all
  # connections have been checked out, and a thread tries to checkout a
  # connection anyway, then ConnectionPool will wait until some other thread
  # has checked in a connection.
  #
  # == Obtaining (checking out) a connection
  #
  # Connections can be obtained and used from a connection pool in several
  # ways:
  #
  # 1. Simply use ActiveRecord::Base.connection as with Active Record 2.1 and
  #    earlier (pre-connection-pooling). Eventually, when you're done with
  #    the connection(s) and wish it to be returned to the pool, you call
  #    ActiveRecord::Base.clear_active_connections!. This will be the
  #    default behavior for Active Record when used in conjunction with
  #    Action Pack's request handling cycle.
  # 2. Manually check out a connection from the pool with
  #    ActiveRecord::Base.connection_pool.checkout. You are responsible for
  #    returning this connection to the pool when finished by calling
  #    ActiveRecord::Base.connection_pool.checkin(connection).
  # 3. Use ActiveRecord::Base.connection_pool.with_connection(&block), which
  #    obtains a connection, yields it as the sole argument to the block,
  #    and returns it to the pool after the block completes.
  #
  # Connections in the pool are actually AbstractAdapter objects (or objects
  # compatible with AbstractAdapter's interface).
  #
  # == Options
  #
  # There are two connection-pooling-related options that you can add to
  # your database connection configuration:
  #
  # * +pool+: number indicating size of connection pool (default 5)
  # * +wait_timeout+: number of seconds to block and wait for a connection
  #   before giving up and raising a timeout error (default 5 seconds).
  class ConnectionPool
    include MonitorMixin
    attr_reader :options, :connections

    # Creates a new ConnectionPool object. +spec+ is a ConnectionSpecification
    # object which describes database connection information (e.g. adapter,
    # host name, username, password, etc), as well as the maximum size for
    # this ConnectionPool.
    #
    # The default ConnectionPool maximum size is 5.
    def initialize(pooled, options)
      super()
      @pooled = pooled
      @options = options

      # The cache of reserved connections mapped to threads
      @reserved_connections = {}

      # The mutex used to synchronize pool access
      @queue = self.new_cond

      # default 5 second timeout unless on ruby 1.9
      @timeout = options[:wait_timeout] || 5

      # default max pool size to 5
      @size = (options[:pool] && options[:pool].to_i) || 5

      @connections = []
      @checked_out = []
    end

    # Retrieve the connection associated with the current thread, or call
    # #checkout to obtain one if necessary.
    #
    # #connection can be called any number of times; the connection is
    # held in a hash keyed by the thread id.
    def connection
      @reserved_connections[current_connection_id] ||= checkout
    end

    # Signal that the thread is finished with the current connection.
    # #release_connection releases the connection-thread association
    # and returns the connection to the pool.
    def release_connection(with_id = current_connection_id)
      conn = @reserved_connections.delete(with_id)
      checkin conn if conn
    end

    # If a connection already exists yield it to the block.  If no connection
    # exists checkout a connection, yield it to the block, and checkin the
    # connection when finished.
    def with_connection
      connection_id = current_connection_id
      fresh_connection = true unless @reserved_connections[connection_id]
      yield connection
    ensure
      release_connection(connection_id) if fresh_connection
    end

    # Returns true if a connection has already been opened.
    def connected?
      synchronize { !@connections.empty? }
    end

    # Disconnects all connections in the pool, and clears the pool.
    def disconnect!
      synchronize do
        @reserved_connections = {}
        @connections.each do |conn|
          checkin conn
          @pooled.__disconnect(conn)
        end
        @connections = []
      end
    end

    # Verify active connections and remove and disconnect connections
    # associated with stale threads.
    def verify_active_connections! #:nodoc:
      synchronize do
        clear_stale_cached_connections!
        @connections.each do |connection|
          @pooled.__disconnect(connection)
        end
      end
    end

    # Return any checked-out connections back to the pool by threads that
    # are no longer alive.
    def clear_stale_cached_connections!
      keys = @reserved_connections.keys - Thread.list.find_all { |t|
        t.alive?
      }.map { |thread| thread.object_id }
      keys.each do |key|
        checkin @reserved_connections[key]
        @reserved_connections.delete(key)
      end
    end

    # Check-out a database connection from the pool, indicating that you want
    # to use it. You should call #checkin when you no longer need this.
    #
    # This is done by either returning an existing connection, or by creating
    # a new connection. If the maximum number of connections for this pool has
    # already been reached, but the pool is empty (i.e. they're all being used),
    # then this method will wait until a thread has checked in a connection.
    # The wait time is bounded however: if no connection can be checked out
    # within the timeout specified for this pool, then a ConnectionTimeoutError
    # exception will be raised.
    #
    # Returns: an AbstractAdapter object.
    #
    # Raises:
    # - ConnectionTimeoutError: no connection can be obtained from the pool
    #   within the timeout period.
    def checkout
      # Checkout an available connection
      synchronize do
        loop do
          conn = if @checked_out.size < @connections.size
                   checkout_existing_connection
                 elsif @connections.size < @size
                   checkout_new_connection
                 end
          return conn if conn

          @queue.wait(@timeout)

          if(@checked_out.size < @connections.size)
            next
          else
            clear_stale_cached_connections!
            if @size == @checked_out.size
              raise ConnectionTimeoutError, "could not obtain a pooled connection#{" within #{@timeout} seconds" if @timeout}.  The max pool size is currently #{@size}; consider increasing it."
            end
          end

        end
      end
    end

    # Check-in a database connection back into the pool, indicating that you
    # no longer need this connection.
    #
    # +conn+: an AbstractAdapter object, which was obtained by earlier by
    # calling +checkout+ on this pool.
    def checkin(conn)
      synchronize do
        @checked_out.delete conn
        @queue.signal
      end
    end

  private
    def current_connection_id #:nodoc:
      Thread.current.object_id
    end

    def checkout_new_connection
      c = @pooled.__connection
      @pooled.__prepare(c)
      @connections << c
      checkout_connection(c)
    end

    def checkout_existing_connection
      c = (@connections - @checked_out).first
      checkout_connection(c)
    end

    def checkout_connection(c)
      @checked_out << c
      c
    end
  end
end
