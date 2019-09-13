require 'spec_helper'

shared_examples 'PaymentIntent API' do
  let(:payment_method) { Stripe::PaymentMethod.create({ type: 'card', card: card }) }
  let(:customer) { Stripe::Customer.create(payment_method: payment_method.id, invoice_settings: { default_payment_method: payment_method.id }) }

  subject(:context) { Stripe::PaymentIntent.create(payment_method: payment_method.id, amount: 100, customer: customer.id, currency: "usd", confirm: true) }

  # without confirmation
  context 'when using card without 3d secure' do
    let(:card) { { number: '4242424242424242', exp_month: 7, exp_year: Time.now.year + 5, cvc: '314' } }

    it "creates a succeeded stripe payment_intent", live: true do
      expect(context.amount).to eq(100)
      expect(context.currency).to eq('usd')
      expect(context.metadata.to_hash).to eq({})
      expect(context.status).to eq('succeeded')
    end
  
    it "confirms a stripe payment_intent", live: true do
      payment_intent = Stripe::PaymentIntent.create(payment_method: payment_method.id, amount: 100, customer: customer.id, currency: "usd")
      confirmed_payment_intent = payment_intent.confirm
      expect(confirmed_payment_intent.status).to eq('succeeded')
    end

    it "retrieves a stripe payment_intent" do
      payment_intent = Stripe::PaymentIntent.retrieve(context.id)
  
      expect(payment_intent.id).to eq(context.id)
      expect(payment_intent.amount).to eq(context.amount)
      expect(payment_intent.currency).to eq(context.currency)
      expect(payment_intent.metadata.to_hash).to eq(context.metadata.to_hash)
    end
  
    it "cannot retrieve a payment_intent that doesn't exist" do
      expect { Stripe::PaymentIntent.retrieve('nope') }.to raise_error {|e|
        expect(e).to be_a Stripe::InvalidRequestError
        expect(e.param).to eq('payment_intent')
        expect(e.http_status).to eq(404)
      }
    end
  
    it "captures a stripe payment_intent" do
      payment_intent = Stripe::PaymentIntent.create(amount: 100, customer: customer.id, currency: "usd")
      confirmed_payment_intent = payment_intent.capture
      expect(confirmed_payment_intent.status).to eq('succeeded')
    end
  
    it "cancels a stripe payment_intent" do
      payment_intent = Stripe::PaymentIntent.create(amount: 100, customer: customer.id, currency: "usd")
      confirmed_payment_intent = payment_intent.cancel
      expect(confirmed_payment_intent.status).to eq('canceled')
    end
  
    it "updates a stripe payment_intent" do
      payment_intent = Stripe::PaymentIntent.retrieve(context.id)
      payment_intent.amount = 200
      payment_intent.save
      updated = Stripe::PaymentIntent.retrieve(context.id)
      expect(updated.amount).to eq(200)
    end
  
    it 'when amount is not integer', live: true do
      expect { Stripe::PaymentIntent.create(amount: 400.2,
                                            customer: customer.id,
                                            currency: 'usd') }.to raise_error { |e|
        expect(e).to be_a Stripe::InvalidRequestError
        expect(e.param).to eq('amount')
        expect(e.http_status).to eq(400)
      }
    end
  
    it 'when amount is negative', live: true do
      expect { Stripe::PaymentIntent.create(amount: -400,
                                            customer: customer.id,
                                            currency: 'usd') }.to raise_error { |e|
        expect(e).to be_a Stripe::InvalidRequestError
        expect(e.param).to eq('amount')
        expect(e.message).to match(/^Invalid.*integer/)
        expect(e.http_status).to eq(400)
      }
    end

    describe "listing payment_intent" do
      before do
        3.times do
          Stripe::PaymentIntent.create(payment_method: payment_method.id, amount: 100, currency: "usd", customer: customer.id, confirm: true)
        end
      end
  
      it "without params retrieves all stripe payment_intent" do
        expect(Stripe::PaymentIntent.all.count).to eq(3)
      end
  
      it "accepts a limit param" do
        expect(Stripe::PaymentIntent.all(limit: 2).count).to eq(2)
      end
    end

    context 'without payment method', live: true do
      it "creates a requires_payment_method stripe payment_intent" do
        pi = Stripe::PaymentIntent.create(amount: 100, customer: customer.id, currency: "usd")
        expect(pi.currency).to eq('usd')
        expect(pi.metadata.to_hash).to eq({})
        expect(pi.status).to eq('requires_payment_method')
      end
  
      it 'when confirm payment without payment_method', live: true do
        expect { Stripe::PaymentIntent.create(amount: 100, customer: customer.id, currency: "usd", confirm: true) }.to raise_error { |e|
          expect(e).to be_a Stripe::InvalidRequestError
          expect(e.http_status).to eq(400)
        }
      end
    end
  end

  context 'when using card with 3d secure' do
    let(:card) { { number: '4000000000003220', exp_month: 7, exp_year: Time.now.year + 5, cvc: '314' } }
    
    it 'created a requires_action stripe payment intent' do
      expect(context.id).to match(/^test_pi/)
      expect(context.amount).to eq(100)
      expect(context.currency).to eq('usd')
      expect(context.metadata.to_hash).to eq({})
      expect(context.status).to eq('requires_action')
    end

    it "confirms a stripe payment_intent" do
      payment_intent = Stripe::PaymentIntent.create(payment_method: payment_method.id, amount: 100, customer: customer.id, currency: "usd")
      confirmed_payment_intent = payment_intent.confirm
      expect(confirmed_payment_intent.status).to eq('requires_action')
    end
  end
end
