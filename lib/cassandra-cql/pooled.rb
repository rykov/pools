require 'pools'

module CassandraCQL; end
unless CassandraCQL.respond_to?(:VERSION)
  require 'cassandra-cql'
end

module CassandraCQL
  class Pooled
    include ::Pools::Pooled

    def initialize(*args)
      @cassandra_args = args.dup
      super
    end

    def __connection
      CassandraCQL::Database.new(*@cassandra_args)
    end

    def __disconnect(client)
      client.disconnect! if client
    end

    preparation_methods :login!, :keyspace=
    connection_methods :execute, :prepare, :keyspaces, :schema
  end
end