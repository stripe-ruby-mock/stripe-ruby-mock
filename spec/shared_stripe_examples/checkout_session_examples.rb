require "spec_helper"

shared_examples "Checkout Session API" do
  let(:line_items) do
    [{
       name: "T-shirt",
       quantity: 2,
       amount: 500,
       currency: "usd",
     }]
  end

  it "creates PaymentIntent with payment mode" do
    session = Stripe::Checkout::Session.create(
      payment_method_types: ["card"],
      line_items: line_items,
      cancel_url: "https://example.com/cancel",
      success_url: "https://example.com/success"
    )

    expect(session.payment_intent).to_not be_empty
    payment_intent = Stripe::PaymentIntent.retrieve(session.payment_intent)
    expect(payment_intent.amount).to eq(1000)
    expect(payment_intent.currency).to eq("usd")
    expect(payment_intent.customer).to eq(session.customer)
  end

  context "when creating a payment" do
    it "requires line_items" do
      expect do
        session = Stripe::Checkout::Session.create(
          customer: "customer_id",
          success_url: "localhost/nada",
          cancel_url: "localhost/nada",
          payment_method_types: ["card"],
        )
      end.to raise_error(Stripe::InvalidRequestError, /line_items/i)

    end
  end

  it "creates SetupIntent with setup mode" do
    session = Stripe::Checkout::Session.create(
      mode: "setup",
      payment_method_types: ["card"],
      cancel_url: "https://example.com/cancel",
      success_url: "https://example.com/success"
    )

    expect(session.setup_intent).to_not be_empty
    setup_intent = Stripe::SetupIntent.retrieve(session.setup_intent)
    expect(setup_intent.payment_method_types).to eq(["card"])
  end

  context "when creating a subscription" do
    it "requires line_items" do
      expect do
        session = Stripe::Checkout::Session.create(
          customer: "customer_id",
          success_url: "localhost/nada",
          cancel_url: "localhost/nada",
          payment_method_types: ["card"],
          mode: "subscription",
        )
      end.to raise_error(Stripe::InvalidRequestError, /line_items/i)

    end
  end

  context "retrieve a checkout session" do
    let(:checkout_session1) { stripe_helper.create_checkout_session }

    it "can be retrieved by id" do
      checkout_session1

      checkout_session = Stripe::Checkout::Session.retrieve(checkout_session1.id)

      expect(checkout_session.id).to eq(checkout_session1.id)
    end

    it "cannot retrieve a checkout session that doesn't exist" do
      expect { Stripe::Checkout::Session.retrieve("nope") }.to raise_error { |e|
        expect(e).to be_a Stripe::InvalidRequestError
        expect(e.param).to eq("checkout_session")
        expect(e.http_status).to eq(404)
      }
    end

    it "can expand setup_intent" do
      initial_session = Stripe::Checkout::Session.create(
        mode: "setup",
        cancel_url: "https://example.com",
        success_url: "https://example.com",
        payment_method_types: ["card"]
      )

      checkout_session = Stripe::Checkout::Session.retrieve(id: initial_session.id, expand: ["setup_intent"])

      expect(checkout_session.setup_intent).to be_a_kind_of(Stripe::SetupIntent)
    end
  end

  context "ui mode" do
    let(:return_url) { "https://stripe.com" }

    it "requires return_url" do
      expect do
        Stripe::Checkout::Session.create
      end.to raise_error(Stripe::InvalidRequestError, "Missing required param: :return_url.")
    end

    it "creates a checkout session with client_secret, return_url" do
      session = Stripe::Checkout::Session.create(line_items: line_items, return_url: return_url)
      expect(session.client_secret).to eq("cs_000000000000000000000000_secret_0000000000000000000000000")
      expect(session.return_url).to eq(return_url)
    end
  end
end
