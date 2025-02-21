module StripeMock
  module Compat
    def self.legacy?
      Gem::Version.new(Stripe::VERSION) < Gem::Version.new('13.0.0')
    end

    def self.method
      return :execute_request if legacy?

      :execute_request_internal
    end
    def self.client
      return Stripe::StripeClient if legacy?

      Stripe::APIRequestor
    end

    def self.active_client
      return client.active_client if legacy?

      client.active_requestor
    end
  end
end
