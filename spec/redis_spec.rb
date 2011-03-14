require File.dirname(__FILE__) + '/spec_helper'
require 'logger'
require 'redis/pooled'

describe Redis::Pooled do
  let(:rpool) { Redis::Pooled.new(:pool => 1) }

  it "create a client" do
    rpool.with_connection do |conn|
      conn.should be_a(Redis)
    end
  end
end
