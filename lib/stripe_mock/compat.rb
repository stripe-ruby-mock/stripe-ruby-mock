module StripeMock
  module Compat
    def self.stripe_gte_13?
      Gem::Version.new(Stripe::VERSION) >= Gem::Version.new('13.0.0')
    end

    def self.method
      return :execute_request unless stripe_gte_13?

      :execute_request_internal
    end

    def self.client
      return Stripe::StripeClient unless stripe_gte_13?

      Stripe::APIRequestor
    end

    def self.client_instance
      @client ||= client.new
    end

    def self.active_client
      return client.active_client unless stripe_gte_13?

      client.active_requestor
    end
  end
end
