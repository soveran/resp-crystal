require "crotest"
require "../src/resp"

REDIS_HOST = ENV.fetch("REDIS_HOST", "localhost")
REDIS_PORT = ENV.fetch("REDIS_PORT", "6379")

def info(c : Resp, section = "default")
  c.call("INFO", section).as String
end

def connect(url : String)
  c = Resp.new(url)
  yield c
ensure
  disconnect(c)
end

def disconnect(c : Nil)
end

def disconnect(c : Resp)
  c.finalize
end
