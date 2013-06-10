module StripeMock

  def self.start_client(port=4999)
    alias_stripe_method :request, StripeMock.method(:redirect_to_mock_server)
    # Ensure client can connect to server
    @client = Jimson::Client.new("http://0.0.0.0:#{port}")
    @client.ping
    @state = 'remote'
  rescue Errno::ECONNREFUSED => e
    raise StripeMock::ServerTimeoutError.new(e)
  end

  def self.stop_client(clear=false)
    return unless @state == 'remote'
    alias_stripe_method :request, @original_request_method
    @client.clear_data if clear == true
    @client = nil
    @state = 'ready'
  end

  def self.get_server_data(key)
    @client.get_data(key)
  end

  def self.set_server_debug(toggle)
    @client.set_debug(toggle)
  end

  def self.clear_server
    @client.clear
  rescue Errno::ECONNREFUSED => e
    raise StripeMock::ServerTimeoutError.new(e)
  end

  private

  def self.redirect_to_mock_server(method, url, api_key, params={}, headers={})
    @client.mock_request(method, url, api_key, params, headers)
  rescue Errno::ECONNREFUSED => e
    raise StripeMock::ServerTimeoutError.new(e)
  rescue StandardError => e
    puts "Unexpected Error: #{e.inspect}"
    {}
  end

end
