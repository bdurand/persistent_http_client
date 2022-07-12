# frozen_string_literal: true

module PersistentHTTPClient
  # Cache of persistent HTTP::Client connections for a specific URL with a set of options.
  class HostClients
    DEFAULT_KEEP_ALIVE_TIMEOUT = 5

    # @param base_url [String, URI] The base URL for the server to connect to.
    # @param options [Hash, HTTP::Client, nil] Default options for the connection.
    def initialize(base_url, options = nil)
      @mutex = Mutex.new
      @http_clients = []
      @base_url = base_url
      @options = (options ? options.dup : {})
      @keep_alive_timeout = (@options.delete(:keep_alive_timeout) || DEFAULT_KEEP_ALIVE_TIMEOUT)
    end

    # Yield a peristent HTTP::Client.
    #
    # @yieldparam http [HTTP::Client]
    #
    # @return [Object] Returns the value returned by the block.
    def client
      http = nil

      # Pop references from the list of clients until a non-garbage collected, non-expired one is found
      @mutex.synchronize do
        until @http_clients.empty?
          client = @http_clients.shift&.object
          if client
            connection = http_connection(client)
            if connection && !connection.expired?
              http = client
              break
            end
          end
        end
      end

      new_connection = http.nil?
      begin
        http ||= new_http_client
        yield(http)
      ensure
        connection = http_connection(http)
        if connection
          if connection.expired?
            http.close
          else
            flush_connection(connection)
            if new_connection
              ObjectSpace.define_finalizer(http) { |object_id| connection.close }
            end
            @mutex.synchronize { @http_clients << Ref::WeakReference.new(http) }
          end
        end
      end
    end

    private

    # Create a new HTTP client.
    def new_http_client
      HTTP::Client.new(@options).persistent(@base_url, timeout: @keep_alive_timeout)
    end

    # Dig into the HTTP::Client to retrieve the connection.
    def http_connection(http)
      http.instance_variable_get(:@connection) if http.instance_variable_defined?(:@connection)
    end

    # Fully read from the connection so all streams are empty and it's ready for the next
    # request.
    def flush_connection(connection)
      while connection.readpartial
        # Fully read any pending response
      end
    end
  end
end
