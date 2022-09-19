require 'rubygems'
$TESTING=true
$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'pools'

RSpec.configure do |config|
  config.after(:each) do
    Pools.handler.pools.clear
  end
end
