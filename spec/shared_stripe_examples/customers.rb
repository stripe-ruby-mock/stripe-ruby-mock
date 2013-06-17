require 'spec_helper'

shared_examples 'Customer API' do

  it "creates a stripe customer" do
    customer = Stripe::Customer.create({
      email: 'johnny@appleseed.com',
      card: 'some_card_token',
      description: "a description"
    })
    expect(customer.id).to match(/^test_cus/)
    expect(customer.email).to eq('johnny@appleseed.com')
    expect(customer.description).to eq('a description')
  end

  it "stores a created stripe customer in memory" do
    customer = Stripe::Customer.create({
      email: 'johnny@appleseed.com',
      card: 'some_card_token'
    })
    customer2 = Stripe::Customer.create({
      email: 'bob@bobbers.com',
      card: 'another_card_token'
    })
    data = test_data_source(:customers)
    expect(data[customer.id]).to_not be_nil
    expect(data[customer.id][:email]).to eq('johnny@appleseed.com')

    expect(data[customer2.id]).to_not be_nil
    expect(data[customer2.id][:email]).to eq('bob@bobbers.com')
  end

  it "retrieves a stripe customer" do
    original = Stripe::Customer.create({
      email: 'johnny@appleseed.com',
      card: 'some_card_token'
    })
    customer = Stripe::Customer.retrieve(original.id)

    expect(customer.id).to eq(original.id)
    expect(customer.email).to eq(original.email)
  end

  it "retrieves a stripe customer with an id that doesn't exist" do
    customer = Stripe::Customer.retrieve('test_customer_x')
    expect(customer.id).to eq('test_customer_x')
    expect(customer.email).to_not be_nil
    expect(customer.description).to_not be_nil
  end

  it "updates a stripe customer" do
    original = Stripe::Customer.retrieve("test_customer_update")
    email = original.email

    original.description = 'new desc'
    original.save

    expect(original.email).to eq(email)
    expect(original.description).to eq('new desc')

    customer = Stripe::Customer.retrieve("test_customer_update")
    expect(customer.email).to eq(original.email)
    expect(customer.description).to eq('new desc')
  end

  it "updates a stripe customer's subscription" do
    customer = Stripe::Customer.retrieve("test_customer_sub")
    sub = customer.update_subscription({ :plan => 'silver' })

    expect(sub.object).to eq('subscription')
    expect(sub.plan.id).to eq('silver')
  end

  it "cancels a stripe customer's subscription" do
    customer = Stripe::Customer.retrieve("test_customer_sub")
    sub = customer.cancel_subscription

    expect(sub.deleted).to eq(true)
  end

end
