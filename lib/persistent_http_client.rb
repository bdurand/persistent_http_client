# frozen_string_literal: true

require "http"
require "ref"

require_relative "persistent_http_client/client_pool"
require_relative "persistent_http_client/host_clients"

module PersistentHTTPClient
  @client_pool = nil

  class << self
    # Get a persistent HTTP connection to a server. Connections will be kept open and
    # reused between calls to this method. Stale connections will be automatically
    # garbage collected if they are not reused.
    #
    # @param base_url [String, URI] The URL for the server to connect to. Any URL can be passed, but
    #   only the protocol, host, and port are used.
    # @param options [Hash, HTTP::Client, nil] Default options for the connection. Connections will only be
    #   reused if the options match.
    #
    # @yieldparam http [HTTP::Client]
    #
    # @return [Object] Returns the value returned by the block.
    def client(base_url, options = nil, &block)
      @client_pool ||= ClientPool.new
      @client_pool.client(base_url, options, &block)
    end
  end
end
