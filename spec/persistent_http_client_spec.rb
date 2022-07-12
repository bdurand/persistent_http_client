# frozen_string_literal: true

require_relative "spec_helper"

describe PersistentHTTPClient do
  it "gets a persistent connection" do
    PersistentHTTPClient.client(TEST_HOST) do |http|
      expect(http.persistent?).to eq true
    end
  end

  it "passes options through to the connection" do
    PersistentHTTPClient.client(TEST_HOST, headers: {"Accept" => "application/json"}) do |http|
      expect(http.default_options.headers).to eq({"Accept" => "application/json"})
    end
  end

  it "reuses a persistent connection for the same host and options" do
    client = nil
    PersistentHTTPClient.client(TEST_HOST) do |http|
      http.get("/test")
      client = http
    end
    PersistentHTTPClient.client(TEST_HOST) do |http|
      expect(http).to eq client
    end
  end

  it "returns the value of the block" do
    retval = PersistentHTTPClient.client(TEST_HOST) { |http| :value }
    expect(retval).to eq :value
  end
end
