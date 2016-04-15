require "./spec_helper"

describe "Resp" do
  it "should encode expressions as RESP" do
    assert_equal "*1\r\n$3\r\nFOO\r\n\r\n", Resp.encode(["FOO"])
  end

  it "should accept host and port" do
    Resp.new("localhost", 6379)
  end

  it "should accept a URI" do
    Resp.new("redis://localhost:6379")
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
