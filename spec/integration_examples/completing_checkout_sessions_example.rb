require 'spec_helper'

shared_examples "Completing Checkout Sessions" do
  let(:test_helper) { StripeMock.create_test_helper }
  before { StripeMock.start }
  after { StripeMock.stop }

  it "can complete payment checkout sessions" do
    session = test_helper.create_checkout_session(mode: "payment")
    payment_method = Stripe::PaymentMethod.create(type: "card")

    payment_intent = test_helper.complete_checkout_session(session, payment_method)

    expect(payment_intent.id).to eq(session.payment_intent)
    expect(payment_intent.payment_method).to eq(payment_method.id)
    expect(payment_intent.status).to eq("succeeded")
  end

  it "can complete setup checkout sessions" do
    session = test_helper.create_checkout_session(mode: "setup")
    payment_method = Stripe::PaymentMethod.create(type: "card")

    setup_intent = test_helper.complete_checkout_session(session, payment_method)

    expect(setup_intent.id).to eq(session.setup_intent)
    expect(setup_intent.payment_method).to eq(payment_method.id)
  end

  it "can complete subscription checkout sessions" do
    session = test_helper.create_checkout_session(mode: "subscription")
    payment_method = Stripe::PaymentMethod.create(type: "card")

    subscription = test_helper.complete_checkout_session(session, payment_method)

    expect(subscription.default_payment_method).to eq(payment_method.id)
  end
end
