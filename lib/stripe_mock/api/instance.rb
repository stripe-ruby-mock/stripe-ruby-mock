module StripeMock

  @state = 'ready'
  @instance = nil
  @original_execute_request_method = Stripe::StripeClient.instance_method(:execute_request)

  def self.start
    return false if @state == 'live'
    @instance = instance = Instance.new
    Stripe::StripeClient.send(:define_method, :execute_request) do |*args|
      instance.mock_request(args[0], args[1], **args[2])
    end
    @state = 'local'
  end

  def self.stop
    return unless @state == 'local'
    restore_stripe_execute_request_method
    @instance = nil
    @state = 'ready'
  end

  # Yield the given block between StripeMock.start and StripeMock.stop
  def self.mock(&block)
    begin
      self.start
      yield
    ensure
      self.stop
    end
  end

  def self.restore_stripe_execute_request_method
    Stripe::StripeClient.send(:define_method, :execute_request, @original_execute_request_method)
  end

  def self.instance; @instance; end
  def self.state; @state; end

end
