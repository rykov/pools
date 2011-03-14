##
# This file adapted from activerecord gem
#

module Pools
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      @app.call(env)
    ensure
      Pools.handler.clear_active_connections!
    end
  end
end