require "crotest"
require "../src/resp"

REDIS_PORT = ENV.fetch("REDIS_PORT", "6379")

def info(c : Resp, section = "default")
  c.call("INFO", section).as String
end
