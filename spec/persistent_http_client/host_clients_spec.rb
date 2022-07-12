# frozen_string_literal: true

require_relative "../spec_helper"

describe PersistentHTTPClient::HostClients do
  let(:clients) { PersistentHTTPClient::HostClients.new(TEST_HOST) }

  it "gets a persistent connection" do
    clients.client do |http|
      expect(http.persistent?).to eq true
    end
  end

  it "returns the value of the block" do
    retval = clients.client { |http| :value }
    expect(retval).to eq :value
  end

  it "passes options through to the connection" do
    clients = PersistentHTTPClient::HostClients.new(TEST_HOST, headers: {"Accept" => "application/json"})
    clients.client do |http|
      expect(http.default_options.headers).to eq({"Accept" => "application/json"})
    end
  end

  it "reuses a persistent connection" do
    client = nil
    clients.client do |http|
      http.get("/test")
      client = http
    end
    clients.client do |http|
      expect(http).to eq client
    end
  end

  it "does not prevent unused connections from being garbage collected" do
    client = nil
    clients.client do |http|
      http.get("/test")
      client = http
    end

    clients.client do |http|
      expect(http).to eq client
    end

    collected = false
    10_000.times do |i|
      1_000_000.times { Object.new }
      GC.start
      clients.client do |http|
        if http != client
          collected = true
        end
      end
      break if collected
      sleep(0.001)
    end
    expect(collected).to eq true
  end

  it "finishes a request so the next thread starts fresh" do
    client = nil
    clients.client do |http|
      client = http
      http.get("/test?1")
    end

    clients.client do |http|
      expect(http).to eq client
      expect(http.get("/test?2").to_s).to eq "Success: 2"
    end
  end
end
