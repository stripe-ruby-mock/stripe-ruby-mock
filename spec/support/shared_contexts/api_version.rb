shared_context "with API version" do |version|
  around do |example|
    original = Stripe.api_version
    Stripe.api_version = version
    example.run
  ensure
    Stripe.api_version = original
  end
end
