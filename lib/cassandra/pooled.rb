require 'pools'

class Cassandra; end
unless Cassandra.respond_to?(:VERSION)
  require 'cassandra/0.8'
end

class Cassandra
  class Pooled
    include ::Pools::Pooled

    def initialize(*args)
      @cassandra_args = args.dup
      super
    end

    def __connection
      Cassandra.new(*@cassandra_args)
    end

    def __disconnect(client)
      client.disconnect! if client
    end

    preparation_methods :login!, :disable_node_auto_discovery!

    connection_methods :keyspace, :keyspaces, :servers, :schema,
      :auth_request, :thrift_client_options, :thrift_client_class,
      :insert, :remove, :count_columns, :multi_count_columns,
      :get_columns, :multi_get_columns, :get, :multi_get, :exists?,
      :get_range, :count_range, :batch, :schema_agreement?, :version,
      :cluster_name, :ring, :partitioner, :truncate!, :clear_keyspace!,
      :add_column_family, :drop_column_family, :rename_column_family,
      :add_keyspace, :drop_keyspace, :rename_keyspace
  end
end