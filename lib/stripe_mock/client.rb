module StripeMock

  class Client
    attr_reader :port, :state

    def initialize(port)
      @port = port
      @pipe = Jimson::Client.new("http://0.0.0.0:#{port}")
      # Ensure client can connect to server
      timeout_wrap { @pipe.ping }
      @state = 'ready'
    end

    def mock_request(method, url, api_key, params={}, headers={})
      timeout_wrap { @pipe.mock_request(method, url, api_key, params, headers) }
    end

    def get_server_data(key)
      timeout_wrap { @pipe.get_data(key) }
    end

    def set_server_debug(toggle)
      timeout_wrap { @pipe.set_debug(toggle) }
    end

    def clear_server_data
      timeout_wrap { @pipe.clear }
    end

    def close!
      @state = 'closed'
      StripeMock.stop_client(:clear_server_data => false)
    end

    def timeout_wrap
      raise ClosedClientConnectionError if @state == 'closed'
      yield
    rescue ClosedClientConnectionError
      raise
    rescue Errno::ECONNREFUSED => e
      raise StripeMock::ServerTimeoutError.new(e)
    rescue StandardError => e
      puts "Unexpected StripeMock Client Error: #{e.inspect}"
      {}
    end
  end

end
