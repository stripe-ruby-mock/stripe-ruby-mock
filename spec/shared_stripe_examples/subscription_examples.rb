require 'spec_helper'

shared_examples 'Customer Subscriptions' do

  context "creating a new subscription" do
    it "adds a new subscription to customer with none" do
      plan = Stripe::Plan.create(id: 'silver', name: 'Silver Plan', amount: 4999)
      customer = Stripe::Customer.create(id: 'test_customer_sub', card: 'tk')

      expect(customer.subscriptions.data).to be_empty
      expect(customer.subscriptions.count).to eq(0)

      sub = customer.subscriptions.create({ :plan => 'silver' })

      expect(sub.object).to eq('subscription')
      expect(sub.plan).to eq('silver')

      customer = Stripe::Customer.retrieve('test_customer_sub')
      expect(customer.subscriptions.data).to_not be_empty
      expect(customer.subscriptions.count).to eq(1)
      expect(customer.subscriptions.data.length).to eq(1)

      expect(customer.subscriptions.data.first.id).to eq(sub.id)
      expect(customer.subscriptions.data.first.plan.to_hash).to eq(plan.to_hash)
      expect(customer.subscriptions.data.first.customer).to eq(customer.id)

    end

    it "correctly sets quantity and application_fee_percent" do
      Stripe::Plan.create(
        :amount => 2500,
        :interval => 'month',
        :name => 'Test plan',
        :currency => 'usd',
        :id => 'silver',
        :statement_description => "testPlan"
      )
      customer = Stripe::Customer.create(id: 'test_customer_sub', card: 'tk')

      subscription = customer.subscriptions.create({
        :plan => "silver", quantity: 2, application_fee_percent: 10})
      expect(subscription.quantity).to eq(2)
      expect(subscription.application_fee_percent).to eq(10)
    end

    it "adds additional subscription to customer with existing subscription" do
      silver =  Stripe::Plan.create(id: 'silver')
      gold =    Stripe::Plan.create(id: 'gold')
      customer = Stripe::Customer.create(id: 'test_customer_sub', card: 'tk', plan: 'gold')

      sub = customer.subscriptions.create({ :plan => 'silver' })

      expect(sub.object).to eq('subscription')
      expect(sub.plan).to eq('silver')

      customer = Stripe::Customer.retrieve('test_customer_sub')
      expect(customer.subscriptions.data).to_not be_empty
      expect(customer.subscriptions.count).to eq(2)
      expect(customer.subscriptions.data.length).to eq(2)

      expect(customer.subscriptions.data.first.plan.to_hash).to eq(gold.to_hash)
      expect(customer.subscriptions.data.first.customer).to eq(customer.id)

      expect(customer.subscriptions.data.last.id).to eq(sub.id)
      expect(customer.subscriptions.data.last.plan.to_hash).to eq(silver.to_hash)
      expect(customer.subscriptions.data.last.customer).to eq(customer.id)
    end

    it "subscribes a cardless customer when specifing a card token" do
      plan = Stripe::Plan.create(id: 'enterprise', amount: 499)
      customer = Stripe::Customer.create(id: 'cardless')

      sub = customer.subscriptions.create({ :plan => 'enterprise', :card => 'card_token' })
      customer = Stripe::Customer.retrieve('cardless')

      expect(customer.subscriptions.data.first.id).to eq(sub.id)
      expect(customer.subscriptions.data.first.customer).to eq(customer.id)

      expect(customer.cards.count).to eq(1)
      expect(customer.cards.data.length).to eq(1)
      expect(customer.default_card).to_not be_nil
      expect(customer.default_card).to eq customer.cards.data.first.id
    end

    it "throws an error when plan does not exist" do
      customer = Stripe::Customer.create(id: 'cardless')

      expect { customer.subscriptions.create({ :plan => 'gazebo' }) }.to raise_error {|e|
        expect(e).to be_a Stripe::InvalidRequestError
        expect(e.http_status).to eq(404)
        expect(e.message).to_not be_nil
      }

      expect(customer.subscriptions.data).to be_empty
      expect(customer.subscriptions.count).to eq(0)
    end

    it "throws an error when subscribing a customer with no card" do
      plan = Stripe::Plan.create(id: 'enterprise', amount: 499)
      customer = Stripe::Customer.create(id: 'cardless')

      expect { customer.subscriptions.create({ :plan => 'enterprise' }) }.to raise_error {|e|
        expect(e).to be_a Stripe::InvalidRequestError
        expect(e.http_status).to eq(400)
        expect(e.message).to_not be_nil
      }

      expect(customer.subscriptions.data).to be_empty
      expect(customer.subscriptions.count).to eq(0)
    end

    it "subscribes a customer with no card to a plan with a free trial" do
      plan = Stripe::Plan.create(id: 'trial', amount: 999, trial_period_days: 14)
      customer = Stripe::Customer.create(id: 'cardless')

      sub = customer.subscriptions.create({ :plan => 'trial' })

      expect(sub.object).to eq('subscription')
      expect(sub.plan).to eq('trial')
      expect(sub.trial_end - sub.trial_start).to eq(14 * 86400)

      customer = Stripe::Customer.retrieve('cardless')
      expect(customer.subscriptions.data).to_not be_empty
      expect(customer.subscriptions.count).to eq(1)
      expect(customer.subscriptions.data.length).to eq(1)

      expect(customer.subscriptions.data.first.id).to eq(sub.id)
      expect(customer.subscriptions.data.first.plan.to_hash).to eq(plan.to_hash)
      expect(customer.subscriptions.data.first.customer).to eq(customer.id)
    end

    it "subscribes a customer with no card to a free plan" do
      plan = Stripe::Plan.create(id: 'free_tier', amount: 0)
      customer = Stripe::Customer.create(id: 'cardless')

      sub = customer.subscriptions.create({ :plan => 'free_tier' })

      expect(sub.object).to eq('subscription')
      expect(sub.plan).to eq('free_tier')

      customer = Stripe::Customer.retrieve('cardless')
      expect(customer.subscriptions.data).to_not be_empty
      expect(customer.subscriptions.count).to eq(1)
      expect(customer.subscriptions.data.length).to eq(1)

      expect(customer.subscriptions.data.first.id).to eq(sub.id)
      expect(customer.subscriptions.data.first.plan.to_hash).to eq(plan.to_hash)
      expect(customer.subscriptions.data.first.customer).to eq(customer.id)
    end

    it "overrides trial length when trial end is set" do
      plan = Stripe::Plan.create(id: 'trial', amount: 999, trial_period_days: 14)
      customer = Stripe::Customer.create(id: 'short_trial')
      trial_end = Time.now.utc.to_i + 3600

      sub = customer.subscriptions.create({ plan: 'trial', trial_end: trial_end })

      expect(sub.object).to eq('subscription')
      expect(sub.plan).to eq('trial')
      expect(sub.current_period_end).to eq(trial_end)
      expect(sub.trial_end).to eq(trial_end)
    end

    it "returns without a trial when trial_end is set to 'now'" do
      plan = Stripe::Plan.create(id: 'trial', amount: 999, trial_period_days: 14)
      customer = Stripe::Customer.create(id: 'no_trial', card: 'tk')

      sub = customer.subscriptions.create({ plan: 'trial', trial_end: "now" })

      expect(sub.object).to eq('subscription')
      expect(sub.plan).to eq('trial')
      expect(sub.status).to eq('active')
      expect(sub.trial_start).to be_nil
      expect(sub.trial_end).to be_nil
    end

    it "raises error when trial_end is not an integer or 'now'" do
      plan = Stripe::Plan.create(id: 'trial', amount: 999, trial_period_days: 14)
      customer = Stripe::Customer.create(id: 'cus_trial')

      expect { customer.subscriptions.create({ plan: 'trial', trial_end: "gazebo" }) }.to raise_error {|e|
        expect(e).to be_a Stripe::InvalidRequestError
        expect(e.http_status).to eq(400)
        expect(e.message).to eq("Invalid timestamp: must be an integer")
      }
    end

    it "raises error when trial_end is set to a time in the past" do
      plan = Stripe::Plan.create(id: 'trial', amount: 999, trial_period_days: 14)
      customer = Stripe::Customer.create(id: 'past_trial')
      trial_end = Time.now.utc.to_i - 3600

      expect { customer.subscriptions.create({ plan: 'trial', trial_end: trial_end }) }.to raise_error {|e|
        expect(e).to be_a Stripe::InvalidRequestError
        expect(e.http_status).to eq(400)
        expect(e.message).to eq("Invalid timestamp: must be an integer Unix timestamp in the future")
      }
    end

    it "raises error when trial_end is set to a time more than five years in the future" do
      plan = Stripe::Plan.create(id: 'trial', amount: 999, trial_period_days: 14)
      customer = Stripe::Customer.create(id: 'long_trial')
      trial_end = Time.now.utc.to_i + 31557600*5 + 3600 # 5 years + 1 hour

      expect { customer.subscriptions.create({ plan: 'trial', trial_end: trial_end }) }.to raise_error {|e|
        expect(e).to be_a Stripe::InvalidRequestError
        expect(e.http_status).to eq(400)
        expect(e.message).to eq("Invalid timestamp: can be no more than five years in the future")
      }
    end
  end

  context "updating a subscription" do

    it "updates a stripe customer's existing subscription" do
      silver = Stripe::Plan.create(id: 'silver')
      gold = Stripe::Plan.create(id: 'gold')
      customer = Stripe::Customer.create(id: 'test_customer_sub', card: 'tk', plan: 'silver')

      sub = customer.subscriptions.retrieve(customer.subscriptions.data.first.id)
      sub.plan = 'gold'
      sub.save

      expect(sub.object).to eq('subscription')
      expect(sub.plan).to eq('gold')

      customer = Stripe::Customer.retrieve('test_customer_sub')
      expect(customer.subscriptions.data).to_not be_empty
      expect(customer.subscriptions.count).to eq(1)
      expect(customer.subscriptions.data.length).to eq(1)

      expect(customer.subscriptions.data.first.id).to eq(sub.id)
      expect(customer.subscriptions.data.first.plan.to_hash).to eq(gold.to_hash)
      expect(customer.subscriptions.data.first.customer).to eq(customer.id)
    end

    it "throws an error when plan does not exist" do
      free = Stripe::Plan.create(id: 'free', amount: 0)
      customer = Stripe::Customer.create(id: 'cardless', plan: 'free')

      sub = customer.subscriptions.retrieve(customer.subscriptions.data.first.id)
      sub.plan = 'gazebo'

      expect { sub.save }.to raise_error {|e|
        expect(e).to be_a Stripe::InvalidRequestError
        expect(e.http_status).to eq(404)
        expect(e.message).to_not be_nil
      }

      customer = Stripe::Customer.retrieve('cardless')
      expect(customer.subscriptions.count).to eq(1)
      expect(customer.subscriptions.data.length).to eq(1)
      expect(customer.subscriptions.data.first.plan.to_hash).to eq(free.to_hash)
    end

    it "throws an error when subscription does not exist" do
      free = Stripe::Plan.create(id: 'free', amount: 0)
      customer = Stripe::Customer.create(id: 'cardless', plan: 'free')

      expect { customer.subscriptions.retrieve("gazebo") }.to raise_error {|e|
        expect(e).to be_a Stripe::InvalidRequestError
        expect(e.http_status).to eq(404)
        expect(e.message).to_not be_nil
      }

      customer = Stripe::Customer.retrieve('cardless')
      expect(customer.subscriptions.count).to eq(1)
      expect(customer.subscriptions.data.length).to eq(1)
      expect(customer.subscriptions.data.first.plan.to_hash).to eq(free.to_hash)
    end

    it "throws an error when updating a customer with no card" do
      free = Stripe::Plan.create(id: 'free', amount: 0)
      paid = Stripe::Plan.create(id: 'enterprise', amount: 499)
      customer = Stripe::Customer.create(id: 'cardless', plan: 'free')

      sub = customer.subscriptions.retrieve(customer.subscriptions.data.first.id)
      sub.plan = 'enterprise'

      expect { sub.save }.to raise_error {|e|
        expect(e).to be_a Stripe::InvalidRequestError
        expect(e.http_status).to eq(400)
        expect(e.message).to_not be_nil
      }

      customer = Stripe::Customer.retrieve('cardless')
      expect(customer.subscriptions.count).to eq(1)
      expect(customer.subscriptions.data.length).to eq(1)
      expect(customer.subscriptions.data.first.plan.to_hash).to eq(free.to_hash)
    end

    it "updates a customer with no card to a plan with a free trial" do
      free = Stripe::Plan.create(id: 'free', amount: 0)
      trial = Stripe::Plan.create(id: 'trial', amount: 999, trial_period_days: 14)
      customer = Stripe::Customer.create(id: 'cardless', plan: 'free')

      sub = customer.subscriptions.retrieve(customer.subscriptions.data.first.id)
      sub.plan = 'trial'
      sub.save

      expect(sub.object).to eq('subscription')
      expect(sub.plan).to eq('trial')

      customer = Stripe::Customer.retrieve('cardless')
      expect(customer.subscriptions.data).to_not be_empty
      expect(customer.subscriptions.count).to eq(1)
      expect(customer.subscriptions.data.length).to eq(1)

      expect(customer.subscriptions.data.first.id).to eq(sub.id)
      expect(customer.subscriptions.data.first.plan.to_hash).to eq(trial.to_hash)
      expect(customer.subscriptions.data.first.customer).to eq(customer.id)
    end

    it "updates a customer with no card to a free plan" do
      free = Stripe::Plan.create(id: 'free', amount: 0)
      gratis = Stripe::Plan.create(id: 'gratis', amount: 0)
      customer = Stripe::Customer.create(id: 'cardless', plan: 'free')

      sub = customer.subscriptions.retrieve(customer.subscriptions.data.first.id)
      sub.plan = 'gratis'
      sub.save

      expect(sub.object).to eq('subscription')
      expect(sub.plan).to eq('gratis')

      customer = Stripe::Customer.retrieve('cardless')
      expect(customer.subscriptions.data).to_not be_empty
      expect(customer.subscriptions.count).to eq(1)
      expect(customer.subscriptions.data.length).to eq(1)

      expect(customer.subscriptions.data.first.id).to eq(sub.id)
      expect(customer.subscriptions.data.first.plan.to_hash).to eq(gratis.to_hash)
      expect(customer.subscriptions.data.first.customer).to eq(customer.id)
    end

    it "sets a card when updating a customer's subscription" do
      free = Stripe::Plan.create(id: 'free', amount: 0)
      paid = Stripe::Plan.create(id: 'paid', amount: 499)
      customer = Stripe::Customer.create(id: 'test_customer_sub', plan: 'free')

      sub = customer.subscriptions.retrieve(customer.subscriptions.data.first.id)
      sub.plan = 'paid'
      sub.card = 'tk'
      sub.save

      customer = Stripe::Customer.retrieve('test_customer_sub')

      expect(customer.cards.count).to eq(1)
      expect(customer.cards.data.length).to eq(1)
      expect(customer.default_card).to_not be_nil
      expect(customer.default_card).to eq customer.cards.data.first.id
    end

    it "overrides trial length when trial end is set" do
      plan = Stripe::Plan.create(id: 'trial', amount: 999, trial_period_days: 14)
      customer = Stripe::Customer.create(id: 'test_trial_end', plan: 'trial')

      sub = customer.subscriptions.retrieve(customer.subscriptions.data.first.id)

      trial_end = Time.now.utc.to_i + 3600
      sub.trial_end = trial_end
      sub.save

      expect(sub.object).to eq('subscription')
      expect(sub.trial_end).to eq(trial_end)
      expect(sub.current_period_end).to eq(trial_end)
    end

    it "returns without a trial when trial_end is set to 'now'" do
      plan = Stripe::Plan.create(id: 'trial', amount: 999, trial_period_days: 14)
      customer = Stripe::Customer.create(id: 'test_trial_end', plan: 'trial')

      sub = customer.subscriptions.retrieve(customer.subscriptions.data.first.id)

      sub.trial_end = "now"
      sub.save

      expect(sub.object).to eq('subscription')
      expect(sub.plan).to eq('trial')
      expect(sub.status).to eq('active')
      expect(sub.trial_start).to be_nil
      expect(sub.trial_end).to be_nil
    end

    it "changes an active subscription to a trial when trial_end is set" do
      plan = Stripe::Plan.create(id: 'no_trial', amount: 999)
      customer = Stripe::Customer.create(id: 'test_trial_end', plan: 'no_trial', card: 'tk')

      sub = customer.subscriptions.retrieve(customer.subscriptions.data.first.id)

      trial_end = Time.now.utc.to_i + 3600
      sub.trial_end = trial_end
      sub.save

      expect(sub.object).to eq('subscription')
      expect(sub.plan).to eq('no_trial')
      expect(sub.status).to eq('trialing')
      expect(sub.trial_end).to eq(trial_end)
      expect(sub.current_period_end).to eq(trial_end)
    end


    it "raises error when trial_end is not an integer or 'now'" do
      plan = Stripe::Plan.create(id: 'no_trial', amount: 999)
      customer = Stripe::Customer.create(id: 'test_trial_end', plan: 'no_trial', card: 'tk')

      sub = customer.subscriptions.retrieve(customer.subscriptions.data.first.id)
      sub.trial_end = "gazebo"

      expect { sub.save }.to raise_error {|e|
        expect(e).to be_a Stripe::InvalidRequestError
        expect(e.http_status).to eq(400)
        expect(e.message).to eq("Invalid timestamp: must be an integer")
      }
    end
  end

  context "cancelling a subscription" do

    it "cancels a stripe customer's subscription", :live => true do
      truth = stripe_helper.create_plan(id: 'the truth')
      customer = Stripe::Customer.create(card: stripe_helper.generate_card_token, plan: "the truth")

      sub = customer.subscriptions.retrieve(customer.subscriptions.data.first.id)
      result = sub.delete

      expect(result.status).to eq('canceled')
      expect(result.cancel_at_period_end).to be_false
      expect(result.canceled_at).to_not be_nil
      expect(result.id).to eq(sub.id)

      customer = Stripe::Customer.retrieve(customer.id)
      expect(customer.subscriptions.data).to be_empty
      expect(customer.subscriptions.count).to eq(0)
      expect(customer.subscriptions.data.length).to eq(0)
    end

    it "cancels a stripe customer's subscription at period end" do
      truth = Stripe::Plan.create(id: 'the_truth')
      customer = Stripe::Customer.create(id: 'test_customer_sub', card: 'tk', plan: "the_truth")

      sub = customer.subscriptions.retrieve(customer.subscriptions.data.first.id)
      result = sub.delete(at_period_end: true)

      expect(result.status).to eq('active')
      expect(result.cancel_at_period_end).to be_true
      expect(result.id).to eq(sub.id)

      customer = Stripe::Customer.retrieve('test_customer_sub')
      expect(customer.subscriptions.data).to_not be_empty
      expect(customer.subscriptions.count).to eq(1)
      expect(customer.subscriptions.data.length).to eq(1)

      expect(customer.subscriptions.data.first.status).to eq('active')
      expect(customer.subscriptions.data.first.cancel_at_period_end).to be_true
      expect(customer.subscriptions.data.first.ended_at).to be_nil
      expect(customer.subscriptions.data.first.canceled_at).to_not be_nil
    end

    it "resumes an at period end cancelled subscription" do
      truth = Stripe::Plan.create(id: 'the_truth')
      customer = Stripe::Customer.create(id: 'test_customer_sub', card: 'tk', plan: "the_truth")

      sub = customer.subscriptions.retrieve(customer.subscriptions.data.first.id)
      result = sub.delete(at_period_end: true)

      sub.plan = 'the_truth'
      sub.save

      customer = Stripe::Customer.retrieve('test_customer_sub')
      expect(customer.subscriptions.data).to_not be_empty
      expect(customer.subscriptions.count).to eq(1)
      expect(customer.subscriptions.data.length).to eq(1)

      expect(customer.subscriptions.data.first.status).to eq('active')
      expect(customer.subscriptions.data.first.cancel_at_period_end).to be_false
      expect(customer.subscriptions.data.first.ended_at).to be_nil
      expect(customer.subscriptions.data.first.canceled_at).to be_nil
    end
  end

  it "doesn't change status of subscription when cancelling at period end" do
    trial = Stripe::Plan.create(id: 'trial', trial_period_days: 14)
    customer = Stripe::Customer.create(id: 'test_customer_sub', card: 'tk', plan: "trial")

    sub = customer.subscriptions.retrieve(customer.subscriptions.data.first.id)
    result = sub.delete(at_period_end: true)

    expect(result.status).to eq('trialing')

    customer = Stripe::Customer.retrieve('test_customer_sub')

    expect(customer.subscriptions.data.first.status).to eq('trialing')
  end

  context "retrieve multiple subscriptions" do

    it "retrieves a list of multiple subscriptions" do
      free = Stripe::Plan.create(id: 'free', amount: 0)
      paid = Stripe::Plan.create(id: 'paid', amount: 499)
      customer = Stripe::Customer.create(id: 'test_customer_sub', card: 'tk', plan: "free")
      customer.subscriptions.create({ :plan => 'paid' })

      customer = Stripe::Customer.retrieve('test_customer_sub')

      list = customer.subscriptions.all

      expect(list.object).to eq("list")
      expect(list.count).to eq(2)
      expect(list.data.length).to eq(2)

      expect(list.data.first.object).to eq("subscription")
      expect(list.data.first.plan.to_hash).to eq(free.to_hash)

      expect(list.data.last.object).to eq("subscription")
      expect(list.data.last.plan.to_hash).to eq(paid.to_hash)
    end

    it "retrieves an empty list if there's no subscriptions" do
      Stripe::Customer.create(id: 'no_subs')
      customer = Stripe::Customer.retrieve('no_subs')

      list = customer.subscriptions.all

      expect(list.object).to eq("list")
      expect(list.count).to eq(0)
      expect(list.data.length).to eq(0)
    end
  end

end
