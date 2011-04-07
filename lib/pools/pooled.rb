require 'active_support/core_ext/array/extract_options'
require 'active_support/concern'

module Pools
  module Pooled
    extend ActiveSupport::Concern
    attr_reader :connection_pool, :preparation_chain

    def initialize(*args)
      options = args.extract_options!
      @preparation_chain = []
      @connection_pool = ConnectionPool.new(self, options)
      Pools.handler.add(@connection_pool, options[:pool_name])
    end

    def with_connection(&block)
      @connection_pool.with_connection(&block)
    end

    def __connection
      # Override in parent
    end

    def __disconnect(connection)
      # Override in parent
    end

    def __prepare(connection)
      @preparation_chain.each { |args| connection.send(*args) }
    end

    module ClassMethods
      def connection_methods(*methods)
        methods.each do |method|
          define_method(method) do |*params|
            with_connection do |client|
              client.send(method, *params)
            end
          end
        end
      end

      def preparation_methods(*methods)
        methods.each do |method|
          define_method(method) do |*params|
            @preparation_chain << ([method] + params)
          end
        end
      end
    end
  end
end