##
# This file adapted from activerecord gem
#

module Pools
  class Handler
    attr_reader :pools

    def initialize(pools = {})
      @pools = pools
    end

    # Add a new connection pool to the mix
    def add(pool, name = nil)
      key = name || pool.object_id
      raise(%Q(Pool "#{name}" already exists)) if @pools[name]
      @pools[name] = pool
    end

    # Returns any connections in use by the current thread back to the
    # pool, and also returns connections to the pool cached by threads
    # that are no longer alive.
    def clear_active_connections!
      @pools.each_value {|pool| pool.release_connection }
    end

    def clear_all_connections!
      @pools.each_value {|pool| pool.disconnect! }
    end

    # Verify active connections.
    def verify_active_connections! #:nodoc:
      @pools.each_value {|pool| pool.verify_active_connections! }
    end

    # Returns true if a connection that's accessible to this class has
    # already been opened.
    def connected?(name)
      conn = retrieve_connection_pool(name)
      conn && conn.connected?
    end

    # Remove the connection for this class. This will close the active
    # connection and the defined connection (if they exist). The result
    # can be used as an argument for establish_connection, for easily
    # re-establishing the connection.
    def remove_connection(name)
      pool = retrieve_connection_pool(name)
      return nil unless pool

      @pools.delete_if { |key, value| value == pool }
      pool.disconnect!
    end

    def retrieve_connection_pool(name)
      pool = @pools[name]
      return pool if pool
    end
  end

  def self.handler
    @@pool_handler ||= Handler.new
  end
end
