pools
-----

<a href="http://badge.fury.io/rb/pools"><img src="https://badge.fury.io/rb/pools@2x.png" alt="Gem Version" height="18"></a>
[![Build Status](https://travis-ci.org/rykov/pools.png)](https://travis-ci.org/rykov/pools)

Provides connection pooling for multiple services that
use persistent connections

Installation
============

    $ gem install pools


Redis Connection Pooling
========================

```ruby
redis = Redis::Pooled.new(regular_init_options)
redis.set("Regular", "Command")

# Check out a connection for multiple commands
redis.with_connection do |conn|
  conn.multi
  a = conn.get('a')
  conn.set('b', a)
  conn.exec
end
```

Author
=====

Michael Rykov :: mrykov@gmail.com
