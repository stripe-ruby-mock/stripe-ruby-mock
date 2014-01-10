require 'spec_helper'

shared_examples 'Customer Subscriptions' do

  it "updates a stripe customer's subscription" do
    plan = Stripe::Plan.create(id: 'silver')
    customer = Stripe::Customer.create(id: 'test_customer_sub', card: 'tk')
    sub = customer.update_subscription({ :plan => 'silver' })

    expect(sub.object).to eq('subscription')
    expect(sub.plan.id).to eq('silver')
    expect(sub.plan.to_hash).to eq(plan.to_hash)

    customer = Stripe::Customer.retrieve('test_customer_sub')
    expect(customer.subscription).to_not be_nil
    expect(customer.subscription.id).to eq(sub.id)
    expect(customer.subscription.plan.id).to eq('silver')
    expect(customer.subscription.customer).to eq(customer.id)
  end

  it "throws an error when subscribing a customer with no card" do
    plan = Stripe::Plan.create(id: 'enterprise', amount: 499)
    customer = Stripe::Customer.create(id: 'cardless')

    expect { customer.update_subscription({ :plan => 'enterprise' }) }.to raise_error {|e|
      expect(e).to be_a Stripe::InvalidRequestError
      expect(e.http_status).to eq(400)
      expect(e.message).to_not be_nil
    }
  end

  it "subscribes a customer with no card to a free plan" do
    plan = Stripe::Plan.create(id: 'free_tier', amount: 0)
    customer = Stripe::Customer.create(id: 'cardless')
    sub = customer.update_subscription({ :plan => 'free_tier' })

    expect(sub.object).to eq('subscription')
    expect(sub.plan.id).to eq('free_tier')
    expect(sub.plan.to_hash).to eq(plan.to_hash)

    customer = Stripe::Customer.retrieve('cardless')
    expect(customer.subscription).to_not be_nil
    expect(customer.subscription.id).to eq(sub.id)
    expect(customer.subscription.plan.id).to eq('free_tier')
    expect(customer.subscription.customer).to eq(customer.id)
  end

  it "subscribes a customer with no card to a plan with a free trial" do
    plan = Stripe::Plan.create(id: 'trial', amount: 999, trial_period_days: 14)
    customer = Stripe::Customer.create(id: 'cardless')
    sub = customer.update_subscription({ :plan => 'trial' })

    expect(sub.object).to eq('subscription')
    expect(sub.plan.id).to eq('trial')
    expect(sub.plan.to_hash).to eq(plan.to_hash)

    customer = Stripe::Customer.retrieve('cardless')
    expect(customer.subscription).to_not be_nil
    expect(customer.subscription.id).to eq(sub.id)
    expect(customer.subscription.plan.id).to eq('trial')
    expect(customer.subscription.customer).to eq(customer.id)
  end

  it "cancels a stripe customer's subscription" do
    Stripe::Plan.create(id: 'the truth')
    customer = Stripe::Customer.create(id: 'test_customer_sub', card: 'tk')
    sub = customer.update_subscription({ :plan => 'the truth' })

    result = customer.cancel_subscription
    expect(result.status).to eq('canceled')
    expect(result.cancel_at_period_end).to be_false
    expect(result.id).to eq(sub.id)

    customer = Stripe::Customer.retrieve('test_customer_sub')
    expect(customer.subscription).to_not be_nil
    expect(customer.subscription.id).to eq(result.id)
  end

  it "cancels a stripe customer's subscription at period end" do
    Stripe::Plan.create(id: 'the truth')
    customer = Stripe::Customer.create(id: 'test_customer_sub', card: 'tk')
    sub = customer.update_subscription({ :plan => 'the truth' })

    result = customer.cancel_subscription(at_period_end: true)
    expect(result.status).to eq('active')
    expect(result.cancel_at_period_end).to be_true
    expect(result.id).to eq(sub.id)

    customer = Stripe::Customer.retrieve('test_customer_sub')
    expect(customer.subscription).to_not be_nil
    expect(customer.subscription.id).to eq(result.id)
  end

  it "cannot update to a plan that does not exist" do
    customer = Stripe::Customer.create(id: 'test_customer_sub')
    expect {
      customer.update_subscription(plan: 'imagination')
    }.to raise_error Stripe::InvalidRequestError
  end

  it "cannot cancel a plan that does not exist" do
    customer = Stripe::Customer.create(id: 'test_customer_sub')
    expect {
      customer.cancel_subscription(plan: 'imagination')
    }.to raise_error Stripe::InvalidRequestError
  end

  it "sets a card when updating a customer's subscription" do
    plan = Stripe::Plan.create(id: 'small')
    customer = Stripe::Customer.create(id: 'test_customer_sub')
    customer.update_subscription(card: 'tk', :plan => 'small')

    customer = Stripe::Customer.retrieve('test_customer_sub')

    expect(customer.cards.count).to eq(1)
    expect(customer.cards.data.length).to eq(1)
    expect(customer.default_card).to_not be_nil
    expect(customer.default_card).to eq customer.cards.data.first.id
  end

end
