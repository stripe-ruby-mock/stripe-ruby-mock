require 'spec_helper'

shared_examples 'PaymentMethod API' do

  it "attaches a stripe payment_method" do
    id = 'pm_1234'
    payment_method = Stripe::PaymentMethod.attach(id, { customer: "cust_123" })
    expect(payment_method.id).to eq(id)
  end

  it "retrieves a stripe payment_method" do
    original = Stripe::PaymentMethod.attach('pm_1234', { customer: "cust_123" })
    payment_method = Stripe::PaymentMethod.retrieve(original.id)
    expect(payment_method.id).to eq(original.id)
  end

  it "cannot retrieve a payment_method that doesn't exist" do
    expect { Stripe::PaymentMethod.retrieve('nope') }.to raise_error { |e|
      expect(e).to be_a Stripe::InvalidRequestError
      expect(e.param).to eq('payment_method')
      expect(e.http_status).to eq(404)
    }
  end

end
