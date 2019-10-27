require "./spec_helper"

describe "Resp" do
  before do
    connect("redis://#{REDIS_HOST}:#{REDIS_PORT}") do |c|
      c.call("FLUSHDB")
    end
  end

  it "should encode expressions as RESP" do
    assert_equal "*1\r\n$3\r\nFOO\r\n", Resp.encode(["FOO"])
  end

  it "should accept host and port" do
    connect("redis://#{REDIS_HOST}:#{REDIS_PORT}") do |c|
      assert_equal "tcp_port:#{REDIS_PORT}", info(c, "server")["tcp_port:#{REDIS_PORT}"]
    end
  end

  it "should accept auth" do
    message = "ERR Client sent AUTH, but no password is set"
    ex = nil

    begin
      connect("redis://:foo@#{REDIS_HOST}:#{REDIS_PORT}") do |c|
        c.ping
      end
      raise Exception.new
    rescue ex : Resp::Error
      assert_equal message, ex.message
    end
  end

  it "should accept db" do
    connect("redis://#{REDIS_HOST}:#{REDIS_PORT}/3") do |c|
      c.call("SET", "foo", "1")
      assert_equal 1, c.call("DBSIZE")

      c.call("SELECT", "0")
      assert_equal 0, c.call("DBSIZE")
    end
  end

  it "should accept a URI without a path" do
    connect("redis://#{REDIS_HOST}:#{REDIS_PORT}") do |c|
      assert_equal "tcp_port:#{REDIS_PORT}", info(c, "server")["tcp_port:#{REDIS_PORT}"]
    end
  end

  it "should accept a URI with an empty path" do
    connect("redis://#{REDIS_HOST}:#{REDIS_PORT}/") do |c|
      assert_equal "tcp_port:#{REDIS_PORT}", info(c, "server")["tcp_port:#{REDIS_PORT}"]
    end
  end

  it "should accept a URI with a numeric path" do
    connect("redis://#{REDIS_HOST}:#{REDIS_PORT}/3") do |c|
      assert_equal "tcp_port:#{REDIS_PORT}", info(c, "server")["tcp_port:#{REDIS_PORT}"]
    end
  end

  it "should accept a URI with an invalid path" do
    connect("redis://#{REDIS_HOST}:#{REDIS_PORT}/a") do |c|
      assert_equal "tcp_port:#{REDIS_PORT}", info(c, "server")["tcp_port:#{REDIS_PORT}"]
    end
  end

  it "should accept commands" do
    connect("redis://#{REDIS_HOST}:#{REDIS_PORT}") do |c|
      assert_equal "PONG", c.call("PING")
    end
  end

  it "should accept arrays as commands" do
    connect("redis://#{REDIS_HOST}:#{REDIS_PORT}") do |c|
      assert_equal "PONG", c.call(["PING"])
    end
  end

  it "should accept non-string arguments" do
    connect("redis://#{REDIS_HOST}:#{REDIS_PORT}") do |c|
      assert_equal "OK", c.call("SET", "foo", 1)
      assert_equal "1",  c.call("GET", "foo")
    end
  end

  it "should pipeline commands" do
    connect("redis://#{REDIS_HOST}:#{REDIS_PORT}") do |c|
      c.queue("ECHO", "hello")
      c.queue("ECHO", "world")

      assert_equal ["hello", "world"], c.commit
    end
  end

  it "should raise Redis errors" do
    connect("redis://#{REDIS_HOST}:#{REDIS_PORT}") do |c|
      assert_raise(Resp::Error) do
        c.call("FOO")
      end

      c.queue("SET", "foo", "42")
      c.queue("SMEMBERS", "foo")
      c.queue("HGETALL", "foo")

      assert_raise(Resp::Error) do
        c.commit
      end
    end
  end

  it "should be able to get the URL back from the client" do
    connect("redis://#{REDIS_HOST}:#{REDIS_PORT}/8") do |c|
      assert_equal "redis://#{REDIS_HOST}:#{REDIS_PORT}/8", c.url
    end
  end

  it "should accept missing methods as commands" do
    connect("redis://#{REDIS_HOST}:#{REDIS_PORT}") do |c|
      assert_equal "PONG", c.ping
      assert_equal "OK", c.set("foo", "42")
      assert_equal "42", c.get("foo")
      
      assert_raise(Resp::Error) do
        c.foo
      end
    end
  end
end
