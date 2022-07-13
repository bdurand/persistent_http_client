# PersistentHTTPClient

[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)

## Usage

This gem provides a mechanism for easily managing persistent connections with the [http gem](https://github.com/httprb/http).

Using persistent connections to HTTP servers can significantly speed up HTTP requests. For short quick requests to an API, the initial connection overhead can be a significant percentage of the time it takes to make the the request. The is especially true if the server is using HTTPS since the TLS handshake is a multi step affair for both the client and server to establish trust with each other. By using persistent connections, the connection and TLS handshake only need to be made once on the initial request. Subsequent requests will just reuse the same connection.

The [http gem](https://github.com/httprb/http) makes creating persistent connections trivial:

```ruby
http = HTTP.persistent("https://example.com/")

```

This works well if you are making muliple connections in a row from the same bit of code. However, it gets much harder to manage if you are making requests to the same server from different parts of the code or from different threads. One solution is to use the [connection_pool gem](https://github.com/mperham/connection_pool), but this requires you to set up and size a separate connection pool for each server you want send requests to. This can introduce an artificial bottleneck since the connection pools will be of a fixed size and if you don't make it big enough, you could end up with threads waiting for a connection.

With this gem, connections pools created as needed, are very lightweight, and do not have a fixed size. If clients are not actively being used, they will either be removed from the pools as the servers close connections or they will be garbage collected by the Ruby VM.

### Examples

```ruby
  # Get a persistent HTTP::Client for requests to https://example.com
  PersistentHTTPClient.client("https://example.com/") do |http|
    http.get("/test.json")
  end

  # You can pass in a full URL when requesting the client as well; this will reuse the same connection as above
  url = "https://example.com/test.json"
  http = PersistentHTTPClient.client(url) do |http|
    http.get(url)
  end

  # Get a persistent HTTP::Client with request options set on it; this will not reuse the same connection as above
  PersistentHTTPClient.client("https://example.com/", timeout: 5, headers: {"Accept" => "application/json"}) do |http|
    http.get("/test.json")
  end
```

The return value of the `PersistentHTTPClient.client` will be the return value of the block. If you return the response object, though, you must read the body before exiting the `client` block. The stream to the server must be flushed before another request can be made, so you will not be able to read from the stream outside the block.

```ruby
  # Bad
  response = PersistentHTTPClient.client("https://example.com") do |http|
    http.get("/test.json")
  end

  # Good
  response = PersistentHTTPClient.client("https://example.com") do |http|
    http.get("/test.json").flush
  end
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem "persistent_http_client"
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install persistent_http_client
```

## Contributing

Open a pull request on GitHub.

Please use the [standardrb](https://github.com/testdouble/standard) syntax and lint your code with `standardrb --fix` before submitting.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
