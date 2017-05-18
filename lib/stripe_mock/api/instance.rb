module StripeMock

  @state = 'ready'
  @instance = nil
  @original_request_method = Stripe::StripeClient.active_client.method(:execute_request)

  def self.start
    return false if @state == 'live'
    @instance = Instance.new
    alias_stripe_method :execute_request, @instance.method(:mock_request)
    @state = 'local'
  end

  def self.stop
    return unless @state == 'local'
    alias_stripe_method :execute_request, @original_request_method
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

  def self.alias_stripe_method(new_name, method_object)
    Stripe::StripeClient.active_client.define_singleton_method(new_name) {|*args| method_object.call(*args) }
  end

  def self.instance; @instance; end
  def self.state; @state; end

end
