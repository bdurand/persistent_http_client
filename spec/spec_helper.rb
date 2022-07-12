# frozen_string_literal: true

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" if File.exist?(ENV["BUNDLE_GEMFILE"])

Bundler.require(:default, :test)

begin
  require "simplecov"
  SimpleCov.start do
    add_filter ["/spec/", "/app/", "/config/", "/db/"]
  end
rescue LoadError
end

require_relative "../lib/persistent_http_client"

require "webrick"

test_server_output = StringIO.new
test_server = WEBrick::HTTPServer.new Port: 8955, Logger: WEBrick::Log.new(test_server_output), AccessLog: []
test_server.mount_proc("/test") do |request, response|
  response["Content-Type"] = "text/plain"
  response.body = "Success: #{request.query_string}"
end

TEST_HOST = "http://localhost:8955"
TEST_URL = "#{TEST_HOST}/test"

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.order = :random

  config.before(:suite) do
    Thread.new { test_server.start }
    started = false
    30.times do
      if HTTP.get(TEST_URL).status.success?
        started = true
        break
      end
      sleep(0.1)
    end
    warn(test_server_output.string) unless started
  end

  config.after(:suite) do
    test_server.shutdown
  end

  config.around do |example|
    disabled = GC.disable
    begin
      example.run
    ensure
      GC.enable if disabled
    end
  end
end
