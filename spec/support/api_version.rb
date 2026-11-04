def basil_api?
  version = Stripe.api_version || (Stripe::ApiVersion::CURRENT if defined?(Stripe::ApiVersion))
  !version.nil? && version.to_s >= "2025-03-31"
end
