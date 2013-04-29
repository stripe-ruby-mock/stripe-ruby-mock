require 'stripe_mock/version'
require 'stripe_mock/data'
require 'stripe_mock/methods'

module StripeMock

  @@init = false
  @@enabled = false

  def self.start
    if @@init == false
      @@request_method = Stripe.method(:request)
      @@init = true
    end
    alias_stripe_method :request, Methods.method(:mock_request)
    @@enabled = true
  end

  def self.stop
    return unless @@enabled == true
    alias_stripe_method :request, @@request_method
    @@enabled = false
  end

  def self.alias_stripe_method(new_name, method_object)
    Stripe.define_singleton_method(new_name) {|*args| method_object.call(*args) }
  end

end
