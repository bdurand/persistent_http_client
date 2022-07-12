# frozen_string_literal: true

require_relative "../spec_helper"

describe PersistentHTTPClient::ClientPool do
  let(:client_pool) { PersistentHTTPClient::ClientPool.new }

  it "gets a persistent connection" do
    client_pool.client(TEST_HOST) do |http|
      expect(http.persistent?).to eq true
    end
  end

  it "passes options through to the connection" do
    client_pool.client(TEST_HOST, headers: {"Accept" => "application/json"}) do |http|
      expect(http.default_options.headers).to eq({"Accept" => "application/json"})
    end
  end

  it "returns the value of the block" do
    retval = client_pool.client(TEST_HOST) { |http| :value }
    expect(retval).to eq :value
  end

  it "reuses a persistent connection for the same host and options" do
    client = nil
    client_pool.client(TEST_HOST) do |http|
      http.get("/test")
      client = http
    end
    client_pool.client(TEST_HOST) do |http|
      expect(http).to eq client
    end
  end

  it "uses different persistent connections for different hosts" do
    client = nil
    client_pool.client(TEST_HOST) do |http|
      http.get("/test")
      client = http
    end
    client_pool.client("https://example.come") do |http|
      expect(http).to_not eq client
    end
  end

  it "uses different persistent connections for different connection options" do
    client = nil
    client_pool.client(TEST_HOST, headers: {"Accept" => "application/json"}) do |http|
      http.get("/test")
      client = http
    end
    client_pool.client(TEST_HOST) do |http|
      expect(http).to_not eq client
    end
  end

  it "should only use the protocol and host for client connections" do
    client = nil
    client_pool.client(TEST_HOST) do |http|
      http.get("/test")
      client = http
    end
    client_pool.client("#{TEST_HOST}/test") do |http|
      expect(http).to eq client
    end
  end

  it "does prevents recent connections from being garbage collected" do
    client = nil
    client_pool.client(TEST_HOST) do |http|
      http.get("/test")
      client = http
    end

    GC.start

    client_pool.client(TEST_HOST) do |http|
      expect(http).to eq client
    end
  end

  it "does not prevent unused connections from being garbage collected" do
    client = nil
    client_pool.client(TEST_HOST) do |http|
      http.get("/test")
      client = http
    end

    client_pool.client(TEST_HOST) do |http|
      expect(http).to eq client
    end

    client_pool.clear_references

    collected = false
    10_000.times do
      1_000_000.times { Object.new }
      GC.start
      client_pool.client(TEST_HOST) do |http|
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
    client_pool.client(TEST_HOST) do |http|
      client = http
      http.get("/test?1")
    end

    client_pool.client(TEST_HOST) do |http|
      expect(http).to eq client
      expect(http.get("/test?2").to_s).to eq "Success: 2"
    end
  end
end
