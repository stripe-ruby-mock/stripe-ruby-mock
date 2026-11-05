require 'spec_helper'

describe StripeMock::ApiVersions do
  let(:stripe_helper) { StripeMock.create_test_helper }
  let(:customer) { Stripe::Customer.create(source: stripe_helper.generate_card_token) }
  let(:plan) { stripe_helper.create_plan(id: 'versioned', product: stripe_helper.create_product.id, amount: 1000, currency: 'usd') }
  let(:subscription) { Stripe::Subscription.create(customer: customer.id, items: [{ plan: plan.id }]) }

  before { StripeMock.start }
  after do
    StripeMock.stop
    StripeMock.strict_api_version = false
    Stripe.api_version = nil
  end

  describe ".version" do
    it "prefers the request's Stripe-Version header" do
      Stripe.api_version = "2024-06-20"
      expect(described_class.version(stripe_version: "2025-03-31.basil")).to eq("2025-03-31.basil")
      expect(described_class.version("Stripe-Version" => "2025-03-31.basil")).to eq("2025-03-31.basil")
    end

    it "falls back to Stripe.api_version" do
      Stripe.api_version = "2024-06-20"
      expect(described_class.version).to eq("2024-06-20")
    end
  end

  describe ".at_least?" do
    it "compares the release date" do
      expect(described_class.at_least?("2025-03-31", stripe_version: "2025-03-31.basil")).to eq(true)
      expect(described_class.at_least?("2025-03-31", stripe_version: "2025-04-30.basil")).to eq(true)
      expect(described_class.at_least?("2025-03-31", stripe_version: "2025-01-27.acacia")).to eq(false)
    end
  end

  describe ".response" do
    let(:body) do
      {
        object: "list",
        data: [{ object: "subscription", current_period_start: 1, current_period_end: 2, discount: nil,
                 items: { object: "list", data: [{ object: "subscription_item" }] } }]
      }
    end

    it "reshapes nested objects for versions on or after a change" do
      result = described_class.response(body, stripe_version: "2025-03-31.basil")
      item = result[:data][0][:items][:data][0]
      expect(item).to include(current_period_start: 1, current_period_end: 2)
      expect(result[:data][0]).to include(current_period_end: 2, discounts: [])
    end

    it "leaves earlier versions alone" do
      result = described_class.response(body, stripe_version: "2025-01-27.acacia")
      expect(result).to eq(body)
    end

    it "does not modify the stored object" do
      described_class.response(body, stripe_version: "2025-03-31.basil")
      expect(body[:data][0][:items][:data][0].keys).to eq([:object])
    end

    it "removes dropped fields in strict mode" do
      StripeMock.strict_api_version = true
      result = described_class.response(body, stripe_version: "2025-03-31.basil")
      expect(result[:data][0].keys).not_to include(:current_period_start, :current_period_end, :discount)
      expect(result[:data][0][:items][:data][0]).to include(current_period_end: 2)
    end
  end

  context "through the API" do
    it "uses the per-request stripe_version", skip: !StripeMock::Compat.stripe_gte_13? && "per-request versions reach the mock on stripe >= 13" do
      Stripe.api_version = "2025-03-31.basil"
      old = Stripe::Subscription.retrieve({ id: subscription.id }, { stripe_version: "2024-06-20" })
      expect(old.items.data.first.to_hash).not_to have_key(:current_period_end)

      current = Stripe::Subscription.retrieve(subscription.id)
      expect(current.items.data.first.current_period_end).to eq(current.current_period_end)
    end

    it "keeps stored data in the internal shape" do
      Stripe.api_version = "2025-03-31.basil"
      subscription
      stored = StripeMock.instance.subscriptions[subscription.id]
      expect(stored[:items][:data].first).not_to have_key(:current_period_end)
    end

    it "omits removed fields in strict mode" do
      Stripe.api_version = "2025-03-31.basil"
      StripeMock.strict_api_version = true
      expect(subscription.to_hash).not_to have_key(:current_period_end)
      expect(subscription.items.data.first.current_period_end).to be_a(Integer)
    end
  end
end
