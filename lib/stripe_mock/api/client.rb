module StripeMock

  def self.client
    @client
  end

  def self.start_client(port=4999)
    return false if @state == 'live'
    return @client unless @client.nil?

    Compat.client.send(:define_method, Compat.method) do |*args, **keyword_args|
      StripeMock.redirect_to_mock_server(*args, **keyword_args)
    end
    @client = StripeMock::Client.new(port)
    @state = 'remote'
    @client
  end

  def self.stop_client(opts={})
    return false unless @state == 'remote'
    @state = 'ready'

    restore_stripe_execute_request_method
    @client.clear_server_data if opts[:clear_server_data] == true
    @client.cleanup
    @client = nil
    true
  end

  private

  def self.redirect_to_mock_server(*args, **kwargs)
    if args.length == 2 && kwargs.key?(:api_key) # Legacy signature
      method, url = args
    elsif args.length == 6 # New signature
      method, url, _base_address, _params, _opts, _usage = args
    else
      raise ArgumentError, "Invalid arguments for mock_request"
    end
    handler = Instance.handler_for_method_url("#{method} #{url}")

    if mock_error = client.error_queue.error_for_handler_name(handler[:name])
      client.error_queue.dequeue
      raise mock_error
    end

    Stripe::Util.symbolize_names client.mock_request(*args, **kwargs)
  end
end
