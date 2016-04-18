require "./spec_helper"

describe "Resp" do
  before do
    c = Resp.new("localhost", 6379)
    c.call("FLUSHDB")
  end

  it "should encode expressions as RESP" do
    assert_equal "*1\r\n$3\r\nFOO\r\n\r\n", Resp.encode(["FOO"])
  end

  it "should accept host and port" do
    c = Resp.new("localhost", 6379)
    assert_equal "tcp_port:6379", info(c, "server")["tcp_port:6379"]
  end

  it "should accept auth" do
    message = "ERR Client sent AUTH, but no password is set"
    ex = nil

    begin
      Resp.new("localhost", 6379, auth: "foo")
      raise Exception.new
    rescue ex : Resp::Error
      assert_equal message, ex.message
    end
  end

  it "should accept db" do
    c = Resp.new("localhost", 6379, db: "3")

    c.call("SET", "foo", "1")
    assert_equal 1, c.call("DBSIZE")

    c.call("SELECT", "0")
    assert_equal 0, c.call("DBSIZE")
  end

  it "should accept a URI without a path" do
    c = Resp.new("redis://localhost:6379")
    assert_equal "tcp_port:6379", info(c, "server")["tcp_port:6379"]
  end

  it "should accept a URI with an empty path" do
    c = Resp.new("redis://localhost:6379/")
    assert_equal "tcp_port:6379", info(c, "server")["tcp_port:6379"]
  end

  it "should accept a URI with a numeric path" do
    c = Resp.new("redis://localhost:6379/3")
    assert_equal "tcp_port:6379", info(c, "server")["tcp_port:6379"]
  end

  it "should accept a URI with an invalid path" do
    c = Resp.new("redis://localhost:6379/a")
    assert_equal "tcp_port:6379", info(c, "server")["tcp_port:6379"]
  end

  it "should accept commands" do
    c = Resp.new("localhost", 6379)

    assert_equal "PONG", c.call("PING")
  end

  it "should accept arrays as commands" do
    c = Resp.new("localhost", 6379)

    assert_equal "PONG", c.call(["PING"])
  end

  it "should pipeline commands" do
    c = Resp.new("localhost", 6379)

    c.queue("ECHO", "hello")
    c.queue("ECHO", "world")

    assert_equal ["hello", "world"], c.commit
  end

  it "should raise Redis errors" do
    c = Resp.new("localhost", 6379)

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
