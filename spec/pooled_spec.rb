require File.dirname(__FILE__) + '/spec_helper'
require 'logger'

class TestPool
  include Pools::Pooled

  class Connection
    attr_accessor :valid, :prepared

    def test_method
      '__TEST__'
    end

    def test_method_with_args(input)
      input
    end

    def test_method_with_kwargs(input: nil)
      input
    end

    def prepare_method(value)
      self.prepared = value
    end

    def yielding_method(value)
      yield(value)
    end
  end

  def __connection
    c = Connection.new
    c.valid = true
    c.prepared = false
    c
  end

  preparation_methods :prepare_method
  connection_methods :test_method, :test_method_with_args, :prepared,
                     :test_method_with_kwargs, :yielding_method
end

describe Pools::Pooled do
  def checkout_connections
    @pool = TestPool.new(:pool => 2, :wait_timeout => 0.3)
    @connections = []
    @timed_out = 0

    4.times do
      Thread.new do
        begin
          @connections << @pool.connection_pool.checkout
        rescue Pools::ConnectionTimeoutError
          @timed_out += 1
        end
      end.join
    end
  end

  it "test timeout" do
    checkout_connections
    @connections.length.should == 2
    @timed_out.should == 2
  end

  def checkout_checkin_connections(pool_size, threads)
    @pool = TestPool.new(:pool => pool_size, :wait_timeout => 0.5)
    @connection_count = 0
    @timed_out = 0
    threads.times do
      Thread.new do
        begin
          conn = @pool.connection_pool.checkout
          sleep 0.1
          @pool.connection_pool.checkin conn
          @connection_count += 1
        rescue ActiveRecord::ConnectionTimeoutError
          @timed_out += 1
        end
      end.join
    end
  end

  it "pass connection checkout" do
    checkout_checkin_connections 1, 2
    @connection_count.should == 2
    @timed_out.should == 0
    @pool.connection_pool.connections.size.should == 1
  end

  it "pass connection checkout overbooking" do
    checkout_checkin_connections 2, 3
    @connection_count.should == 3
    @timed_out.should == 0
    @pool.connection_pool.connections.size.should == 1
  end

  it "should check out an existing connection" do
    cpool = TestPool.new(:pool => 1).connection_pool
    orig_conn = cpool.checkout
    cpool.checkin(orig_conn)
    conn = cpool.checkout
    conn.should == orig_conn
    conn.should be_a(TestPool::Connection)
    cpool.checkin(conn)
  end

  it "should not be connected on init" do
    cpool = TestPool.new(:pool => 1).connection_pool
    expect(cpool).to_not be_connected
    cpool.with_connection { }
    expect(cpool).to be_connected
  end

  it "with_connection provides a connection" do
    pool = TestPool.new
    pool.with_connection do |conn|
      conn.should be_a(TestPool::Connection)
    end
  end

  it "respond to client methods" do
    pool = TestPool.new
    pool.test_method.should == '__TEST__'
    pool.test_method_with_args('hi').should == 'hi'
    pool.test_method_with_kwargs(input: 'hi').should == 'hi'
  end

  it "respond to yielding methods" do
    pool = TestPool.new
    pool.yielding_method(15) do |value|
      value.should == 15
    end
  end

  it "not prematurely call preparation methods" do
    expect(TestPool.new.prepared).to eq(false)
  end

  it "not prematurely call preparation methods" do
    pool = TestPool.new
    pool.prepare_method(15)
    pool.prepared.should == 15
  end
end
