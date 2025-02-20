module Compat
  def self.client
    if Gem::Version.new(Stripe::VERSION) >= Gem::Version.new('13.0.0')
      Stripe::APIRequestor.new
    else
      Stripe::StripeClient.new
    end
  end
end
