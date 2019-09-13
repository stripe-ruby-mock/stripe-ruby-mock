require 'spec_helper'

shared_examples 'PaymentMethod API' do
  let(:card) { { number: '4242424242424242', exp_month: 7, exp_year: 2022, cvc: '314' } }

  subject(:context) { Stripe::PaymentMethod.create({ type: 'card', card: card }) }

  it "creates a stripe payment_method with valid card", live: true do
    expect(context).to be_a Stripe::PaymentMethod
    expect(context.type).to eq('card')
    expect(context.card.exp_month).to eq(7)
    expect(context.card.exp_year).to eq(2022)
  end

  it "retrieves a stripe payment_method" do
    payment_method = Stripe::PaymentMethod.retrieve(context.id)

    expect(payment_method.id).to eq(context.id)
    expect(payment_method.type).to eq(context.type)
    expect(payment_method.card.to_hash).to eq(context.card.to_hash)
  end

  it "attaches a stripe payment_method to customer", live: true do
    customer = Stripe::Customer.create(email: 'alice@bob.com')
    context.attach(customer: customer.id)
    expect(context.customer).to eq(customer.id)
  end

  it "detaches a stripe payment_method from customer", live: true do
    customer = Stripe::Customer.create(email: 'alice@bob.com')
    context.attach(customer: customer.id)
    expect(context.customer).to eq(customer.id)
    context.detach

    expect(context.customer).to eq(nil)
  end

  it "cannot retrieve a payment_method that doesn't exist", live: true do
    expect { Stripe::PaymentMethod.retrieve('non_exists') }.to raise_error {|e|
      expect(e).to be_a Stripe::InvalidRequestError
      expect(e.param).to eq('payment_method')
      expect(e.http_status).to eq(404)
    }
  end

  it "updates a stripe payment_method with customer attached to it", live: true do
    customer = Stripe::Customer.create(email: 'alice@bob.com')
    payment_method = Stripe::PaymentMethod.retrieve(context.id)
    payment_method.attach(customer: customer.id)

    payment_method.card = { exp_month: 8 }
    payment_method.save
    expect(payment_method.card.exp_month).to eq 8
  end

  it "cannot update a stripe payment_method without attach it to customer", live: true do
    payment_method = Stripe::PaymentMethod.retrieve(context.id)

    payment_method.card = { exp_month: 8 }
    expect { payment_method.save }.to raise_error { |e|
      expect(e).to be_a Stripe::InvalidRequestError
      expect(e.message).to eq('You must save this PaymentMethod to a customer before you can update it.')
      expect(e.http_status).to eq(400)
    }
  end

  describe "listing payment_methods" do
    before do
      3.times do
        Stripe::PaymentMethod.create({ type: 'card', card: card })
      end
    end

    it "without params retrieves all stripe payment_method" do
      expect(Stripe::PaymentMethod.all.count).to eq(3)
    end

    it "accepts a limit param" do
      expect(Stripe::PaymentMethod.all(limit: 2).count).to eq(2)
    end
  end

  it "cannot create a stripe payment_method without card params", live: true do
    expect { Stripe::PaymentMethod.create({ type: 'card' }) }.to raise_error { |e|
      expect(e).to be_a Stripe::InvalidRequestError
      expect(e.param).to eq('card')
      expect(e.message).to match(/^Missing required param/)
      expect(e.http_status).to eq(400)
    }
  end
end
