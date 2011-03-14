require 'redis-store'
require 'redis/pooled'

class Redis
  class PooledStore < Pooled
    include Store::Ttl, Store::Interface

    def initialize(options = { })
      super
      _extend_marshalling options
    end

    def self.rails3? #:nodoc:
      defined?(::Rails) && ::Rails::VERSION::MAJOR == 3
    end

    def to_s
      with_connection do |c|
        "Redis::Pooled => #{c.host}:#{c.port} against DB #{c.db}"
      end
    end

  private
    def _extend_marshalling(options) # Copied from Store
      @marshalling = !(options[:marshalling] === false)
      extend Store::Marshalling if @marshalling
    end
  end

  class << Store
    def new(*args)
      if args.size == 1 && args.first.is_a?(Hash) && args.first[:pool]
        PooledStore.new(*args)
      else
        super(*args)
      end
    end
  end
end

