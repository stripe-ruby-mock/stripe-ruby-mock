require 'spec_helper'

shared_examples 'Checkout API' do

  it "creates a stripe checkout session" do
    session = Stripe::Checkout::Session.create({
      payment_method_types: ['card'],
      line_items: [{
        name: 'T-shirt',
        quantity: 1,
        amount: 500,
        currency: 'usd',
      }],
    })
    expect(session.id).to match(/^test_cs/)
    expect(session.line_items.count).to eq(1)
  end

  describe "idempotency" do
    let(:checkout_session_params) {{
      payment_method_types: ['card'],
      line_items: [{
        name: 'T-shirt',
        quantity: 1,
        amount: 500,
        currency: 'usd',
      }],
    }}
    let(:checkout_session_headers) {{
      idempotency_key: 'onceisenough'
    }}

    it "returns the original session if the same idempotency_key is passed in" do
      session1 = Stripe::Checkout::Session.create(checkout_session_params, checkout_session_headers)
      session2 = Stripe::Checkout::Session.create(checkout_session_params, checkout_session_headers)

      expect(session1).to eq(session2)
    end

    context 'different key' do
      let(:different_checkout_session_headers) {{
        idempotency_key: 'thisoneisdifferent'
      }}

      it "returns different session if different idempotency_keys are used for each session" do
        session1 = Stripe::Checkout::Session.create(checkout_session_params, checkout_session_headers)
        session2 = Stripe::Checkout::Session.create(checkout_session_params, different_checkout_session_headers)

        expect(session1).not_to eq(session2)
      end
    end
  end
end
