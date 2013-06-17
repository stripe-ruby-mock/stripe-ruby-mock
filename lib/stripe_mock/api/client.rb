module StripeMock

  def self.client; @client; end

  def self.start_client(port=4999)
    return @client unless @client.nil?

    alias_stripe_method :request, StripeMock.method(:redirect_to_mock_server)
    @client = StripeMock::Client.new(port)
    @state = 'remote'
    @client
  end

  def self.stop_client(opts={})
    return false unless @state == 'remote'
    @state = 'ready'

    alias_stripe_method :request, @original_request_method
    @client.clear_data if opts[:clear_server_data] == true
    @client.close!
    @client = nil
    true
  end

  private

  def self.redirect_to_mock_server(method, url, api_key, params={}, headers={})
    if @remote_state_pending_error
      raise @remote_state_pending_error
      @remote_state_pending_error = nil
    end
    Stripe::Util.symbolize_names @client.mock_request(method, url, api_key, params, headers)
  end

end
