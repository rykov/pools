require 'pools'
require 'redis'

class Redis
  class Pooled
    include ::Pools::Pooled

    def initialize(options = {})
      @redis_options = options
      super
    end

    def __connection
      Redis.connect(@redis_options)
    end

    def __disconnect(client)
      client.quit if client
    end

    # Method not supported:
    # Subscribe/Unsubscribe methods and the following...
    # :auth, :select, :discard, :quit, :watch, :unwatch
    # :exec, :multi, :disconnect

    connection_methods :info, :config, :flushdb, :flushall, :save,
      :bgsave, :bgrewriteaof, :get, :getset, :mget, :append, :substr,
      :strlen, :hgetall, :hget, :hdel, :hkeys, :keys, :randomkey,
      :echo, :ping, :lastsave, :dbsize, :exists, :llen, :lrange,
      :ltrim, :lindex, :linsert, :lset, :lrem, :rpush, :rpushx,
      :lpush, :lpushx, :rpop, :blpop, :brpop, :rpoplpush, :lpop,
      :smembers, :sismember, :sadd, :srem, :smove, :sdiff, :sdiffstore,
      :sinter, :sinterstore, :sunion, :sunionstore, :spop, :scard,
      :srandmember, :zadd, :zrank, :zrevrank, :zincrby, :zcard,
      :zrange, :zrangebyscore, :zcount, :zrevrange, :zremrangebyscore,
      :zremrangebyrank, :zscore, :zrem, :zinterstore, :zunionstore,
      :move, :setnx, :del, :rename, :renamenx, :expire, :persist,
      :ttl, :expireat, :hset, :hsetnx, :hmset, :mapped_hmset, :hmget,
      :mapped_hmget, :hlen, :hvals, :hincrby, :hexists, :monitor,
      :debug, :sync, :[], :[]=, :set, :setex, :mset, :mapped_mset,
      :msetnx, :mapped_msetnx, :mapped_mget, :sort, :incr, :incrby,
      :decr, :decrby, :type, :publish, :id
  end
end