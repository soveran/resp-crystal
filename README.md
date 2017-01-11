# Resp

Lightweight [RESP](http://redis.io/topics/protocol) client that
can be used for interacting with Redis and Disque servers.

## Usage

```crystal
require "resp"

client = Resp.new("redis://localhost:6379")

client.call("SET", "foo", "42")
client.call("GET", "foo") #=> "42"
```

## Pipelining

You can pipeline commands by using the `queue`/`commit` methods.

```crystal
require "resp"

client = Resp.new("redis://localhost:6379")

client.queue("ECHO", "foo")
client.queue("ECHO", "bar")

client.commit #=> ["foo", "bar"]
```

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  resp:
    github: soveran/resp-crystal
    branch: master
```
