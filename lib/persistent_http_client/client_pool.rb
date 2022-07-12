# frozen_string_literal: true

module PersistentHTTPClient
  # Pool of  persistent HTTP::Client objects. The pooled clients are stored keyed
  # by the base URL of the server they connect to and any client options. References
  # to the client objects are only weakly held in memory and will be automatically
  # closed and garbage collected if they are not being used.
  class ClientPool
    DEFAULT_KEEP_REFERENCES_COUNT = 20

    # @param keep_references_count [Integer] Number of recently used connections to keep hard references
    #   to so they won't be garbage collected (default 20). Connections in excess of this number can be
    #   garbage collected when the Ruby VM needs more memory.
    def initialize(keep_references_count: DEFAULT_KEEP_REFERENCES_COUNT)
      @mutex = Mutex.new
      @host_clients = Ref::WeakValueMap.new
      @references = []
      @keep_references_count = keep_references_count.to_i
    end

    # Get a persistent HTTP::Client connection to the specified URL with the specified options set.
    #
    # @param base_url [String, URI] The URL for the server to connect to. Any URL can be passed, but
    #   only the protocol, host, and port are used.
    # @param options [Hash, HTTP::Client, nil] Default options for the connection. Connections will only be
    #   reused if the options match.
    #
    # @yieldparam http [HTTP::Client]
    #
    # @return [Object] Returns the value returned by the block.
    def client(base_url, options = nil)
      unless block_given?
        raise ArgumentError, "block required"
      end

      options = (options.respond_to?(:default_options) ? options.default_options : options.to_h) || {}
      options = options.collect { |key, value| [key.to_sym, value] }.to_h
      base_url = URI.join(base_url.to_s, "/").to_s
      clients = host_clients(base_url, options)

      clients.client do |http|
        keep_reference(http, clients)
        yield(http)
      end
    end

    # Clear the list hard references kept for recent connections.
    # @api private
    def clear_references
      @mutex.synchronize { @references.clear }
    end

    private

    # @return [PersistentHTTPClient::HostClients]
    def host_clients(base_url, options)
      key = pool_key(base_url, options)
      clients = @host_clients[key]
      unless clients
        @mutex.synchronize do
          clients = @host_clients[key]
          unless clients
            clients = HostClients.new(base_url, options)
            @host_clients[key] = clients
          end
        end
      end
      clients
    end

    # @return [String]
    def pool_key(base_url, options)
      options.merge(base_url: base_url)
    end

    # Add a hard reference to a connection while keeping the list of references at a constant size.
    # @return [void]
    def keep_reference(http, host_clients)
      object = [http, host_clients]
      unless @references.last == object
        @mutex.synchronize do
          @references.delete(object)
          @references << object
          @references.shift if @references.size > @keep_references_count
        end
      end
    end
  end
end
