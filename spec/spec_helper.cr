require "crotest"
require "../src/resp"

def info(c : Resp, section = "default")
  c.call("INFO", section).as String
end
