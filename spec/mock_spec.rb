require 'spec_helper'
require 'stripe_mock'

describe StripeMock do

  before { StripeMock.start }
  after  { StripeMock.stop }

  it "should override stripe's request method" do
    Stripe.request(:xtest, '/', 'abcde') # no error
  end

  it "should revert overriding stripe's request method" do
    Stripe.request(:xtest, '/', 'abcde') # no error
    StripeMock.stop
    expect { Stripe.request(:x, '/', 'abcde') }.to raise_error
  end

  it "should create a stripe customer" do
    customer = Stripe::Customer.create({
      email: 'johnny@appleseed.com',
      card: 'some_card_token',
      description: "a description"
    })
    expect(customer.email).to eq('johnny@appleseed.com')
    expect(customer.description).to eq('a description')
  end

  it "should retrieve a stripe customer" do
    customer = Stripe::Customer.retrieve("test_customer")
    expect(customer.id).to eq('test_customer')
  end

  it "should update a stripe customer's subscription" do
    customer = Stripe::Customer.retrieve("test_customer")
    sub = customer.update_subscription({ :plan => 'silver' })

    expect(sub.object).to eq('subscription')
    expect(sub.plan.identifier).to eq('silver')
  end

  it "should create a stripe invoice item" do
    invoice = Stripe::InvoiceItem.create({
      amount: 1099,
      customer: 1234,
      currency: 'USD',
      description: "invoice desc"
    }, 'abcde')

    expect(invoice.amount).to eq(1099)
    expect(invoice.description).to eq('invoice desc')
  end

end
