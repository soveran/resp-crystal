# Copyright (c) 2016 Michel Martens
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
require "socket"
require "uri"

class Resp
  class Error < Exception
  end

  class ProtocolError < Exception
  end

  alias Reply = Nil | Int64 | String | Array(Reply)

  def self.encode(args : Enumerable)
    String.build do |res|
      res << sprintf("*%d\r\n", args.size)

      args.each do |arg|
        str = arg.to_s
        res << sprintf("$%d\r\n%s\r\n", str.bytesize, str)
      end
    end
  end

  def self.encode(*args)
    encode(args)
  end

  getter :url

  def initialize(@url : String)
    uri = URI.parse(@url)

    host = uri.host || "localhost"
    port = uri.port || 6379
    auth = uri.password
    db   = uri.path.to_s[/\d+$/]?

    @sock = TCPSocket.new(host, port.to_i)
    @buff = Array(String).new
    @errs = Array(String).new

    call("AUTH", auth) if auth
    call("SELECT", db) if db
  end

  def finalize
    @sock.close
  end

  def send_command(arg)
    @sock << arg
  end

  def discard_eol
    @sock.skip(2)
  end

  def readstr
    @sock.gets || raise ProtocolError.new
  end

  def readnum
    readstr.to_i64
  end

  def readerr
    readstr.tap do |err|
      @errs.push(err)
    end
  end

  def read_reply
    case @sock.read_char

    # RESP status
    when '+' then readstr

    # RESP error
    when '-' then readerr

    # RESP integer
    when ':' then readnum

    # RESP string
    when '$'
      size = readnum

      if size == -1
        return nil
      elsif size == 0
        return ""
      end

      string = String.new(size) do |str|
        @sock.read_fully(Slice.new(str, size))
        {size, 0}
      end

      discard_eol
      return string

    # RESP array
    when '*'
      size = readnum
      list = Array(Reply).new

      if size == -1
        return nil
      elsif size == 0
        return list
      end

      size.times do
        list << read_reply
      end

      return list
    else
      raise ProtocolError.new
    end
  end

  def call(args : Enumerable)
    send_command(Resp.encode(args))
    result = read_reply

    if @errs.empty?
      return result
    else
      fail
    end
  end

  def call(*args)
    call(args)
  end

  def reset
    @buff.clear
  end

  def queue(args : Enumerable)
    @buff << Resp.encode(args)
  end

  def queue(*args)
    queue(args)
  end

  def commit
    @buff.each do |arg|
      send_command(arg)
    end

    list = Array(Reply).new

    @buff.size.times do
      list << read_reply
    end

    if @errs.empty?
      return list
    else
      fail
    end

  ensure
    reset
  end

  private def fail
    raise Error.new(@errs.join(". "))
  ensure
    @errs.clear
  end

  def quit
    call("QUIT")
  end

  macro method_missing(m)
    call({{m.args.unshift(m.name.id.stringify)}})
  end
end
