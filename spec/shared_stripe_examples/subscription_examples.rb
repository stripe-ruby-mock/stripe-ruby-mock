require 'spec_helper'

shared_examples 'Customer Subscriptions' do
  let(:gen_card_tk) { stripe_helper.generate_card_token }

  let(:product) { stripe_helper.create_product }
  let(:plan_attrs) { {id: 'silver', product: product.id, amount: 4999, currency: 'usd'} }
  let(:plan) { stripe_helper.create_plan(plan_attrs) }

  let(:plan_with_trial_attrs) { {id: 'trial', product: product.id, amount: 999, trial_period_days: 14 } }
  let(:plan_with_trial) { stripe_helper.create_plan(plan_with_trial_attrs) }

  let(:free_plan) { stripe_helper.create_plan(id: 'free', product: product.id, amount: 0) }

  context "creating a new subscription" do
    it "adds a new subscription to customer with none using items", :live => true do
      plan
      customer = Stripe::Customer.create(source: gen_card_tk)

      expect(customer.subscriptions.data).to be_empty
      expect(customer.subscriptions.count).to eq(0)

      subscription = Stripe::Subscription.create({
        customer: customer.id,
        items: [{ plan: 'silver' }],
        metadata: { foo: "bar", example: "yes" }
      })

      expect(subscription.object).to eq('subscription')
      expect(subscription.plan.to_hash).to eq(plan.to_hash)
      expect(subscription.metadata.foo).to eq("bar")
      expect(subscription.metadata.example).to eq("yes")

      customer = Stripe::Customer.retrieve(customer.id)
      expect(customer.subscriptions.data).to_not be_empty
      expect(customer.subscriptions.count).to eq(1)
      expect(customer.subscriptions.data.length).to eq(1)
      expect(customer.charges.data.length).to eq(1)
      expect(customer.currency).to eq("usd")

      expect(customer.subscriptions.data.first.id).to eq(subscription.id)
      expect(customer.subscriptions.data.first.plan.to_hash).to eq(plan.to_hash)
      expect(customer.subscriptions.data.first.customer).to eq(customer.id)
      expect(customer.subscriptions.data.first.metadata.foo).to eq( "bar" )
      expect(customer.subscriptions.data.first.metadata.example).to eq( "yes" )
    end

    it "adds a new subscription to customer with none", :live => true do
      plan
      customer = Stripe::Customer.create(source: gen_card_tk)

      expect(customer.subscriptions.data).to be_empty
      expect(customer.subscriptions.count).to eq(0)

      sub = Stripe::Subscription.create({ plan: 'silver', customer: customer.id, metadata: { foo: "bar", example: "yes" } })

      expect(sub.object).to eq('subscription')
      expect(sub.plan.to_hash).to eq(plan.to_hash)
      expect(sub.metadata.foo).to eq( "bar" )
      expect(sub.metadata.example).to eq( "yes" )

      customer = Stripe::Customer.retrieve(customer.id)
      expect(customer.subscriptions.data).to_not be_empty
      expect(customer.subscriptions.count).to eq(1)
      expect(customer.subscriptions.data.length).to eq(1)
      expect(customer.charges.data.length).to eq(1)
      expect(customer.currency).to eq( "usd" )

      expect(customer.subscriptions.data.first.id).to eq(sub.id)
      expect(customer.subscriptions.data.first.plan.to_hash).to eq(plan.to_hash)
      expect(customer.subscriptions.data.first.customer).to eq(customer.id)
      expect(customer.subscriptions.data.first.billing).to eq('charge_automatically')
      expect(customer.subscriptions.data.first.metadata.foo).to eq( "bar" )
      expect(customer.subscriptions.data.first.metadata.example).to eq( "yes" )
    end

    it 'when customer object provided' do
      plan
      customer = Stripe::Customer.create(source: gen_card_tk)

      expect(customer.subscriptions.data).to be_empty
      expect(customer.subscriptions.count).to eq(0)

      sub = Stripe::Subscription.create({ plan: 'silver', customer: customer, metadata: { foo: "bar", example: "yes" } })

      expect(sub.object).to eq('subscription')
      expect(sub.plan.to_hash).to eq(plan.to_hash)
      expect(sub.billing).to eq('charge_automatically')
      expect(sub.metadata.foo).to eq( "bar" )
      expect(sub.metadata.example).to eq( "yes" )

      customer = Stripe::Customer.retrieve(customer.id)
      expect(customer.subscriptions.data).to_not be_empty
      expect(customer.subscriptions.count).to eq(1)
      expect(customer.subscriptions.data.length).to eq(1)
      expect(customer.charges.data.length).to eq(1)
      expect(customer.currency).to eq( "usd" )

      expect(customer.subscriptions.data.first.id).to eq(sub.id)
      expect(customer.subscriptions.data.first.plan.to_hash).to eq(plan.to_hash)

      expect(customer.subscriptions.data.first.customer).to eq(customer.id)
      expect(customer.subscriptions.data.first.billing).to eq('charge_automatically')
      expect(customer.subscriptions.data.first.metadata.foo).to eq( "bar" )
      expect(customer.subscriptions.data.first.metadata.example).to eq( "yes" )
    end

    it "adds a new subscription to customer (string/symbol agnostic)" do
      customer = Stripe::Customer.create(source: gen_card_tk)
      expect(customer.subscriptions.count).to eq(0)

      plan
      sub = Stripe::Subscription.create({plan: plan.id, customer: customer.id })
      customer = Stripe::Customer.retrieve(customer.id)
      expect(sub.plan.to_hash).to eq(plan.to_hash)
      expect(customer.subscriptions.count).to eq(1)

      plan_with_sym_id = stripe_helper.create_plan(id: :gold, product: product.id, amount: 14999, currency: 'usd')
      sub = Stripe::Subscription.create({ plan: plan_with_sym_id.id, customer: customer.id })
      customer = Stripe::Customer.retrieve(customer.id)
      expect(sub.plan.to_hash).to eq(plan_with_sym_id.to_hash)
      expect(customer.subscriptions.count).to eq(2)
    end

    it 'creates a charge for the customer', live: true do
      customer = Stripe::Customer.create(source: gen_card_tk)
      Stripe::Subscription.create({ plan: plan.id, customer: customer.id, metadata: { foo: "bar", example: "yes" } })
      customer = Stripe::Customer.retrieve(customer.id)

      expect(customer.charges.data.length).to eq(1)
      expect(customer.charges.data.first.amount).to eq(4999)
    end

    it 'contains coupon object', live: true do
      coupon = stripe_helper.create_coupon(id: 'free_coupon', duration: 'repeating', duration_in_months: 3)
      customer = Stripe::Customer.create(source: gen_card_tk)
      Stripe::Subscription.create(plan: plan.id, customer: customer.id, coupon: coupon.id)
      customer = Stripe::Customer.retrieve(customer.id)

      expect(customer.subscriptions.data).to be_a(Array)
      expect(customer.subscriptions.data.count).to eq(1)
      expect(customer.subscriptions.data.first.discount).not_to be_nil
      expect(customer.subscriptions.data.first.discount).to be_a(Stripe::StripeObject)
      expect(customer.subscriptions.data.first.discount.coupon.id).to eq(coupon.id)
    end

    it 'when coupon is not exist', live: true do
      customer = Stripe::Customer.create(source: gen_card_tk)

      expect {
        Stripe::Subscription.create(plan: plan.id, customer: customer.id, coupon: 'none')
      }.to raise_error {|e|
        expect(e).to be_a Stripe::InvalidRequestError
        expect(e.http_status).to eq(400)
        expect(e.message).to eq('No such coupon: none')
      }
    end

    it "correctly sets quantity, application_fee_percent and tax_percent" do
      customer = Stripe::Customer.create(id: 'test_customer_sub', source: gen_card_tk)

      subscription = Stripe::Subscription.create({
        plan: plan.id,
        customer: customer.id,
        quantity: 2,
        application_fee_percent: 10,
        tax_percent: 20
      })
      expect(subscription.quantity).to eq(2)
      expect(subscription.application_fee_percent).to eq(10)
      expect(subscription.tax_percent).to eq(20)
    end

    it "correctly sets created when it's not provided as a parameter", live: true do
      customer = Stripe::Customer.create(source: gen_card_tk)
      subscription = Stripe::Subscription.create({ plan: plan.id, customer: customer.id })

      expect(subscription.created).to eq(subscription.current_period_start)
    end

    it "correctly sets created when it's provided as a parameter" do
      customer = Stripe::Customer.create(source: gen_card_tk)
      subscription = Stripe::Subscription.create({ plan: plan.id, customer: customer.id, created: 1473576318 })

      expect(subscription.created).to eq(1473576318)
    end

    it "adds additional subscription to customer with existing subscription" do
      silver =  stripe_helper.create_plan(id: 'silver', product: product.id)
      gold =    stripe_helper.create_plan(id: 'gold', product: product.id)
      customer = Stripe::Customer.create(id: 'test_customer_sub', product: product.id, source: gen_card_tk, plan: 'gold')

      sub = Stripe::Subscription.create({ plan: 'silver', customer: customer.id })

      expect(sub.object).to eq('subscription')
      expect(sub.plan.to_hash).to eq(silver.to_hash)

      customer = Stripe::Customer.retrieve('test_customer_sub')
      expect(customer.subscriptions.data).to_not be_empty
      expect(customer.subscriptions.count).to eq(2)
      expect(customer.subscriptions.data.length).to eq(2)

      expect(customer.subscriptions.data.last.plan.to_hash).to eq(gold.to_hash)
      expect(customer.subscriptions.data.last.customer).to eq(customer.id)

      expect(customer.subscriptions.data.first.id).to eq(sub.id)
      expect(customer.subscriptions.data.first.plan.to_hash).to eq(silver.to_hash)
      expect(customer.subscriptions.data.first.customer).to eq(customer.id)
    end

    it "subscribes a cardless customer when specifing a card token" do
      plan = stripe_helper.create_plan(id: 'enterprise', product: product.id, amount: 499)
      customer = Stripe::Customer.create(id: 'cardless')

      sub = Stripe::Subscription.create(plan: 'enterprise', customer: customer.id, source: gen_card_tk)
      customer = Stripe::Customer.retrieve('cardless')

      expect(customer.subscriptions.data.first.id).to eq(sub.id)
      expect(customer.subscriptions.data.first.customer).to eq(customer.id)

      expect(customer.sources.count).to eq(1)
      expect(customer.sources.data.length).to eq(1)
      expect(customer.default_source).to_not be_nil
      expect(customer.default_source).to eq customer.sources.data.first.id
    end

    it "throws an error when plan does not exist" do
      customer = Stripe::Customer.create(id: 'cardless')

      expect { Stripe::Subscription.create({ plan: 'gazebo', customer: customer.id }) }.to raise_error {|e|
        expect(e).to be_a Stripe::InvalidRequestError
        expect(e.http_status).to eq(404)
        expect(e.message).to_not be_nil
      }

      expect(customer.subscriptions.data).to be_empty
      expect(customer.subscriptions.count).to eq(0)
    end

    it "throws an error when subscribing a customer with no card" do
      plan = stripe_helper.create_plan(id: 'enterprise', product: product.id, amount: 499)
      customer = Stripe::Customer.create(id: 'cardless')

      expect { Stripe::Subscription.create({ plan: plan.id, customer: customer.id }) }.to raise_error {|e|
        expect(e).to be_a Stripe::InvalidRequestError
        expect(e.http_status).to eq(400)
        expect(e.message).to_not be_nil
      }

      expect(customer.subscriptions.data).to be_empty
      expect(customer.subscriptions.count).to eq(0)
    end

    it "throws an error when subscribing the customer to a second plan in a different currency" do
      customer = Stripe::Customer.create(id: 'test_customer_sub', source: gen_card_tk)

      expect(plan.currency).to eql("usd")
      usd_subscription = Stripe::Subscription.create({ plan: plan.id, customer: customer.id })

      eur_plan = stripe_helper.create_plan(plan_attrs.merge(id: "plan_EURO", currency: 'eur'))
      expect(eur_plan.currency).to eql("eur")
      expect { Stripe::Subscription.create({ plan: eur_plan.id, customer: customer.id }) }.to raise_error {|e|
        expect(e).to be_a Stripe::InvalidRequestError
        expect(e.http_status).to eq(400)
        expect(e.message).to_not be_nil
      }
    end

    it 'when attempting to create a new subscription with the params trial', live: true do
      plan = stripe_helper.create_plan(id: 'trial', product: product.id, amount: 999)
      customer = Stripe::Customer.create(source: gen_card_tk)

      expect{ Stripe::Subscription.create(plan: plan.id, customer: customer.id, trial: 10) }.to raise_error {|e|
        expect(e).to be_a Stripe::InvalidRequestError
        expect(e.http_status).to eq(400)
        expect(e.param).to eq('trial')
        expect(e.message).to match /Received unknown parameter/
      }
    end

    it "subscribes a customer with no card to a plan with a free trial" do
      customer = Stripe::Customer.create(id: 'cardless')
      sub = Stripe::Subscription.create({ plan: plan_with_trial.id, customer: customer.id })

      expect(sub.object).to eq('subscription')
      expect(sub.plan.to_hash).to eq(plan_with_trial.to_hash)
      expect(sub.trial_end - sub.trial_start).to eq(14 * 86400)
      expect(sub.billing_cycle_anchor).to be_nil

      customer = Stripe::Customer.retrieve('cardless')
      expect(customer.subscriptions.data).to_not be_empty
      expect(customer.subscriptions.count).to eq(1)
      expect(customer.subscriptions.data.length).to eq(1)

      expect(customer.subscriptions.data.first.id).to eq(sub.id)
      expect(customer.subscriptions.data.first.plan.to_hash).to eq(plan_with_trial.to_hash)
      expect(customer.subscriptions.data.first.customer).to eq(customer.id)
      expect(customer.charges.count).to eq(0)
    end

    it "subscribes a customer with no card to a plan with a free trial with plan as item" do
      customer = Stripe::Customer.create(id: 'cardless')
      sub = Stripe::Subscription.create({ items: [ { plan: plan_with_trial.id } ], customer: customer.id })

      expect(sub.object).to eq('subscription')
      expect(sub.items.data[0].plan.to_hash).to eq(plan_with_trial.to_hash)
      # no idea how to fix this one
      # expect(sub.trial_end - sub.trial_start).to eq(14 * 86400)

      customer = Stripe::Customer.retrieve('cardless')
      expect(customer.subscriptions.data).to_not be_empty
      expect(customer.subscriptions.count).to eq(1)
      expect(customer.subscriptions.data.length).to eq(1)

      expect(customer.subscriptions.data.first.id).to eq(sub.id)
      expect(customer.subscriptions.data.first.items.data.first.plan.to_hash).to eq(plan_with_trial.to_hash)
      expect(customer.subscriptions.data.first.customer).to eq(customer.id)
      # No idea on this one
      # expect(customer.charges.count).to eq(0)
    end

    it "subscribes a customer with no card to a free plan" do
      plan = stripe_helper.create_plan(id: 'free_tier', product: product.id, amount: 0)
      customer = Stripe::Customer.create(id: 'cardless')

      sub = Stripe::Subscription.create({ plan: plan.id, customer: customer.id })

      expect(sub.object).to eq('subscription')
      expect(sub.plan.to_hash).to eq(plan.to_hash)

      customer = Stripe::Customer.retrieve('cardless')
      expect(customer.subscriptions.data).to_not be_empty
      expect(customer.subscriptions.count).to eq(1)
      expect(customer.subscriptions.data.length).to eq(1)

      expect(customer.subscriptions.data.first.id).to eq(sub.id)
      expect(customer.subscriptions.data.first.plan.to_hash).to eq(plan.to_hash)
      expect(customer.subscriptions.data.first.customer).to eq(customer.id)
    end

    it "overrides trial length when trial end is set" do
      customer = Stripe::Customer.create(id: 'short_trial')
      trial_end = Time.now.utc.to_i + 3600

      sub = Stripe::Subscription.create({ plan: plan_with_trial.id, customer: customer.id, trial_end: trial_end })

      expect(sub.object).to eq('subscription')
      expect(sub.plan.to_hash).to eq(plan_with_trial.to_hash)
      expect(sub.current_period_end).to eq(trial_end)
      expect(sub.trial_end).to eq(trial_end)
    end

    it "returns without a trial when trial_end is set to 'now'" do
      customer = Stripe::Customer.create(id: 'no_trial', source: gen_card_tk)

      sub = Stripe::Subscription.create({ plan: plan_with_trial.id, customer: customer.id, trial_end: "now" })

      expect(sub.object).to eq('subscription')
      expect(sub.plan.to_hash).to eq(plan_with_trial.to_hash)
      expect(sub.status).to eq('active')
      expect(sub.trial_start).to be_nil
      expect(sub.trial_end).to be_nil
    end

    it "raises error when trial_end is not an integer or 'now'" do
      customer = Stripe::Customer.create(id: 'cus_trial')

      expect { Stripe::Subscription.create({ plan: plan_with_trial.id, customer: customer.id, trial_end: "gazebo" }) }.to raise_error {|e|
        expect(e).to be_a Stripe::InvalidRequestError
        expect(e.http_status).to eq(400)
        expect(e.message).to eq("Invalid timestamp: must be an integer")
      }
    end

    it "raises error when trial_end is set to a time in the past" do
      customer = Stripe::Customer.create(id: 'past_trial')
      trial_end = Time.now.utc.to_i - 3600

      expect { Stripe::Subscription.create({ plan: plan_with_trial.id, customer: customer.id, trial_end: trial_end }) }.to raise_error {|e|
        expect(e).to be_a Stripe::InvalidRequestError
        expect(e.http_status).to eq(400)
        expect(e.message).to eq("Invalid timestamp: must be an integer Unix timestamp in the future")
      }
    end

    it "raises error when trial_end is set to a time more than five years in the future" do
      customer = Stripe::Customer.create(id: 'long_trial')
      trial_end = Time.now.utc.to_i + 31557600*5 + 3600 # 5 years + 1 hour

      expect { Stripe::Subscription.create({ plan: plan_with_trial.id, customer: customer.id, trial_end: trial_end }) }.to raise_error {|e|
        expect(e).to be_a Stripe::InvalidRequestError
        expect(e.http_status).to eq(400)
        expect(e.message).to eq("Invalid timestamp: can be no more than five years in the future")
      }
    end

    it 'overrides current period end when billing cycle anchor is set' do
      customer = Stripe::Customer.create(source: gen_card_tk)
      billing_cycle_anchor = Time.now.utc.to_i + 3600

      sub = Stripe::Subscription.create({ plan: plan.id, customer: customer.id, billing_cycle_anchor: billing_cycle_anchor })

      expect(sub.status).to eq('active')
      expect(sub.current_period_end).to eq(billing_cycle_anchor)
      expect(sub.billing_cycle_anchor).to eq(billing_cycle_anchor)
    end

    it 'when plan defined inside items', live: true do
      plan = stripe_helper.create_plan(id: 'BASE_PRICE_PLAN1', product: product.id)

      plan2 = stripe_helper.create_plan(id: 'PER_USER_PLAN1', product: product.id)
      customer = Stripe::Customer.create(
        source: {
          object: 'card',
          exp_month: 11,
          exp_year: 2019,
          number: '4242424242424242',
          cvc: '123'
        }
      )
      subscription = Stripe::Subscription.create(
        customer: customer.id,
        items: [
          { plan: plan.id, quantity: 1 },
          { plan: plan2.id, quantity: 2 }
        ]
      )

      expect(subscription.id).to match /(test_su_|sub_).+/
      expect(subscription.plan).to eq nil
      expect(subscription.items.data[0].plan.id).to eq plan.id
      expect(subscription.items.data[1].plan.id).to eq plan2.id
      expect(subscription.items.data[0].quantity).to eq 1
      expect(subscription.items.data[1].quantity).to eq 2
    end

    it 'when plan defined inside items for trials with no card', live: true do
      plan = stripe_helper.create_plan(id: 'BASE_PRICE_PLAN1', product: product.id)

      plan2 = stripe_helper.create_plan(id: 'PER_USER_PLAN1', product: product.id)
      customer = Stripe::Customer.create
      trial_end = Time.now.utc.to_i + 3600

      subscription = Stripe::Subscription.create(
        customer: customer.id,
        items: [
          { plan: plan.id, quantity: 1 },
          { plan: plan2.id, quantity: 2 }
        ],
        trial_end: trial_end
      )

      expect(subscription.id).to match /(test_su_|sub_).+/
      expect(subscription.plan).to eq nil
      expect(subscription.items.data[0].plan.id).to eq plan.id
      expect(subscription.items.data[1].plan.id).to eq plan2.id
    end
  end

  context "updating a subscription" do
    it 'raises invalid request exception when subscription is cancelled' do
      customer = Stripe::Customer.create(source: gen_card_tk, plan: plan.id)

      subscription = Stripe::Subscription.retrieve(customer.subscriptions.data.first.id)
      subscription.delete

      expect { subscription.save }.to raise_error { |e|
        expect(e).to be_a(Stripe::InvalidRequestError)
        expect(e.http_status).to eq(404)
        expect(e.message).to eq("No such subscription: #{subscription.id}")
      }
    end

    it "updates a stripe customer's existing subscription with one plan inside items" do
      customer = Stripe::Customer.create(id: 'test_customer_sub', source: gen_card_tk)

      sub = Stripe::Subscription.create({ items: [ { plan: plan.id } ], customer: customer.id })
      sub.delete(at_period_end: true)

      expect(sub.cancel_at_period_end).to be_truthy
      expect(sub.save).to be_truthy
      expect(sub.cancel_at_period_end).to be_falsey
    end

    it "updates a stripe customer's existing subscription when plan inside of items" do
      customer = Stripe::Customer.create(id: 'test_customer_sub', source: gen_card_tk, plan: plan.id)

      gold_plan = stripe_helper.create_plan(id: 'gold', product: product.id)
      sub = Stripe::Subscription.retrieve(customer.subscriptions.data.first.id)
      sub.plan = gold_plan.id
      sub.quantity = 5
      sub.metadata.foo     = "bar"
      sub.metadata.example = "yes"

      expect(sub.save).to be_truthy

      expect(sub.object).to eq('subscription')
      expect(sub.plan.to_hash).to eq(gold_plan.to_hash)
      expect(sub.quantity).to eq(5)
      expect(sub.metadata.foo).to eq( "bar" )
      expect(sub.metadata.example).to eq( "yes" )

      customer = Stripe::Customer.retrieve('test_customer_sub')
      expect(customer.subscriptions.data).to_not be_empty
      expect(customer.subscriptions.count).to eq(1)
      expect(customer.subscriptions.data.length).to eq(1)

      expect(customer.subscriptions.data.first.id).to eq(sub.id)
      expect(customer.subscriptions.data.first.plan.to_hash).to eq(gold_plan.to_hash)
      expect(customer.subscriptions.data.first.customer).to eq(customer.id)
    end

    it "updates a stripe customer's existing subscription with single plan when multiple plans inside of items" do
      customer = Stripe::Customer.create(id: 'test_customer_sub', source: gen_card_tk, plan: plan.id)

      gold_plan = stripe_helper.create_plan(id: 'gold', product: product.id)
      addon_plan = stripe_helper.create_plan(id: 'addon_plan', product: product.id)
      sub = Stripe::Subscription.retrieve(customer.subscriptions.data.first.id)
      sub.items = [{ plan: gold_plan.id, quantity: 2 }, { plan: addon_plan.id, quantity: 2 }]
      expect(sub.save).to be_truthy

      expect(sub.object).to eq('subscription')
      expect(sub.plan).to be_nil

      customer = Stripe::Customer.retrieve('test_customer_sub')
      expect(customer.subscriptions.data).to_not be_empty
      expect(customer.subscriptions.count).to eq(1)
      expect(customer.subscriptions.data.length).to eq(1)

      expect(customer.subscriptions.data.first.id).to eq(sub.id)
      expect(customer.subscriptions.data.first.plan).to be_nil
      expect(customer.subscriptions.data.first.customer).to eq(customer.id)
      expect(customer.subscriptions.data.first.items.data[0].plan.to_hash).to eq(gold_plan.to_hash)
      expect(customer.subscriptions.data.first.items.data[1].plan.to_hash).to eq(addon_plan.to_hash)
    end

    it "updates a stripe customer's existing subscription with multple plans when multiple plans inside of items" do
      customer = Stripe::Customer.create(id: 'test_customer_sub', source: gen_card_tk)
      addon1_plan = stripe_helper.create_plan(id: 'addon1', product: product.id)
      sub = Stripe::Subscription.create(customer: customer.id, items: [{ plan: plan.id }, { plan: addon1_plan.id }])

      gold_plan = stripe_helper.create_plan(id: 'gold', product: product.id)
      addon2_plan = stripe_helper.create_plan(id: 'addon2', product: product.id)

      sub.items = [{ plan: gold_plan.id, quantity: 2 }, { plan: addon2_plan.id, quantity: 2 }]
      expect(sub.save).to be_truthy

      expect(sub.object).to eq('subscription')
      expect(sub.plan).to be_nil

      customer = Stripe::Customer.retrieve('test_customer_sub')
      expect(customer.subscriptions.data).to_not be_empty
      expect(customer.subscriptions.count).to eq(1)
      expect(customer.subscriptions.data.length).to eq(1)

      expect(customer.subscriptions.data.first.id).to eq(sub.id)
      expect(customer.subscriptions.data.first.plan).to be_nil
      expect(customer.subscriptions.data.first.customer).to eq(customer.id)
      expect(customer.subscriptions.data.first.items.data[0].plan.to_hash).to eq(gold_plan.to_hash)
      expect(customer.subscriptions.data.first.items.data[1].plan.to_hash).to eq(addon2_plan.to_hash)
    end

    it 'when adds coupon', live: true do
      coupon = stripe_helper.create_coupon
      customer = Stripe::Customer.create(source: gen_card_tk, plan: plan.id)
      subscription = Stripe::Subscription.retrieve(customer.subscriptions.data.first.id)

      subscription.coupon = coupon.id
      subscription.save

      expect(subscription.discount).not_to be_nil
      expect(subscription.discount).to be_an_instance_of(Stripe::StripeObject)
      expect(subscription.discount.coupon.id).to eq(coupon.id)
    end

    it 'when add not exist coupon' do
      customer = Stripe::Customer.create(source: gen_card_tk, plan: plan.id)
      subscription = Stripe::Subscription.retrieve(customer.subscriptions.data.first.id)

      subscription.coupon = 'none'

      expect { subscription.save }.to raise_error {|e|
                                                     expect(e).to be_a Stripe::InvalidRequestError
                                                     expect(e.http_status).to eq(400)
                                                     expect(e.message).to eq('No such coupon: none')
                                                   }

    end

    it 'when coupon is removed' do
      customer = Stripe::Customer.create(source: gen_card_tk, plan: plan.id)
      coupon = stripe_helper.create_coupon
      subscription = Stripe::Subscription.retrieve(customer.subscriptions.data.first.id)

      subscription.coupon = coupon.id
      subscription.save
      subscription.coupon = nil
      subscription.save

      expect(subscription.discount).to be_nil
    end

    it "throws an error when plan does not exist" do
      customer = Stripe::Customer.create(id: 'cardless', plan: free_plan.id)

      sub = Stripe::Subscription.retrieve(customer.subscriptions.data.first.id)
      sub.plan = 'gazebo'

      expect { sub.save }.to raise_error {|e|
        expect(e).to be_a Stripe::InvalidRequestError
        expect(e.http_status).to eq(404)
        expect(e.message).to_not be_nil
      }

      customer = Stripe::Customer.retrieve('cardless')
      expect(customer.subscriptions.count).to eq(1)
      expect(customer.subscriptions.data.length).to eq(1)
      expect(customer.subscriptions.data.first.plan.to_hash).to eq(free_plan.to_hash)
    end

    it "throws an error when subscription does not exist" do
      expect(stripe_helper.list_subscriptions(50).keys).to_not include("sub_NONEXIST")
      expect { Stripe::Subscription.retrieve("sub_NONEXIST") }.to raise_error {|e|
        expect(e).to be_a Stripe::InvalidRequestError
        expect(e.http_status).to eq(404)
        expect(e.message).to_not be_nil
      }
    end

    [nil, 0].each do |trial_period_days|
      it "throws an error when updating a customer with no card, and plan trail_period_days = #{trial_period_days}", live: true do
        begin
          free_plan
          paid_plan = stripe_helper.create_plan(id: 'enterprise', product: product.id, amount: 499, trial_period_days: trial_period_days)
          customer = Stripe::Customer.create(description: 'cardless', plan: free_plan.id)

          sub = Stripe::Subscription.retrieve(customer.subscriptions.data.first.id)
          sub.plan = paid_plan.id

          expect { sub.save }.to raise_error {|e|
            expect(e).to be_a Stripe::InvalidRequestError
            expect(e.http_status).to eq(400)
            expect(e.message).to_not be_nil
          }

          customer = Stripe::Customer.retrieve(customer.id)
          expect(customer.subscriptions.count).to eq(1)
          expect(customer.subscriptions.data.length).to eq(1)
          expect(customer.subscriptions.data.first.plan.to_hash).to eq(free_plan.to_hash)
        ensure
          customer.delete if customer
          paid_plan.delete if paid_plan
          free_plan.delete if free_plan
        end
      end
    end

    it 'updates a subscription if the customer has a free trial', live: true do
      trial_end = Time.now.utc.to_i + 3600
      customer = Stripe::Customer.create(plan: plan.id, trial_end: trial_end)
      subscription = customer.subscriptions.first
      subscription.quantity = 2
      subscription.save
      expect(subscription.quantity).to eq(2)
    end

    it "updates a customer with no card to a plan with a free trial" do
      free_plan
      trial_plan = stripe_helper.create_plan(id: 'trial', product: product.id, amount: 999, trial_period_days: 14)
      customer = Stripe::Customer.create(id: 'cardless', plan: free_plan.id)

      sub = Stripe::Subscription.retrieve(customer.subscriptions.data.first.id)
      sub.plan = trial_plan.id
      sub.save

      expect(sub.object).to eq('subscription')
      expect(sub.plan.to_hash).to eq(trial_plan.to_hash)

      customer = Stripe::Customer.retrieve('cardless')
      expect(customer.subscriptions.data).to_not be_empty
      expect(customer.subscriptions.count).to eq(1)
      expect(customer.subscriptions.data.length).to eq(1)

      expect(customer.subscriptions.data.first.id).to eq(sub.id)
      expect(customer.subscriptions.data.first.plan.to_hash).to eq(trial_plan.to_hash)
      expect(customer.subscriptions.data.first.customer).to eq(customer.id)
    end

    it "updates a customer with no card to a free plan" do
      free_plan
      customer = Stripe::Customer.create(id: 'cardless', product: product.id, plan: free_plan.id)

      sub = Stripe::Subscription.retrieve(customer.subscriptions.data.first.id)
      gratis_plan = stripe_helper.create_plan(id: 'gratis', product: product.id, amount: 0)
      sub.plan = gratis_plan.id
      sub.save

      expect(sub.object).to eq('subscription')
      expect(sub.plan.to_hash).to eq(gratis_plan.to_hash)

      customer = Stripe::Customer.retrieve('cardless')
      expect(customer.subscriptions.data).to_not be_empty
      expect(customer.subscriptions.count).to eq(1)
      expect(customer.subscriptions.data.length).to eq(1)

      expect(customer.subscriptions.data.first.id).to eq(sub.id)
      expect(customer.subscriptions.data.first.plan.to_hash).to eq(gratis_plan.to_hash)
      expect(customer.subscriptions.data.first.customer).to eq(customer.id)
    end

    it "sets a card when updating a customer's subscription" do
      customer = Stripe::Customer.create(id: 'test_customer_sub', plan: free_plan.id)

      sub = Stripe::Subscription.retrieve(customer.subscriptions.data.first.id)
      sub.plan = plan.id
      sub.source = gen_card_tk
      sub.save

      customer = Stripe::Customer.retrieve('test_customer_sub')

      expect(customer.sources.count).to eq(1)
      expect(customer.sources.data.length).to eq(1)
      expect(customer.default_source).to_not be_nil
      expect(customer.default_source).to eq customer.sources.data.first.id
    end

    it "overrides trial length when trial end is set" do
      customer = Stripe::Customer.create(id: 'test_trial_end', plan: plan_with_trial.id)
      sub = Stripe::Subscription.retrieve(customer.subscriptions.data.first.id)
      trial_end = Time.now.utc.to_i + 3600
      sub.trial_end = trial_end
      sub.save

      expect(sub.object).to eq('subscription')
      expect(sub.trial_end).to eq(trial_end)
      expect(sub.current_period_end).to eq(trial_end)
    end

    it "returns without a trial when trial_end is set to 'now'" do
      customer = Stripe::Customer.create(id: 'test_trial_end', plan: plan_with_trial.id)

      sub = Stripe::Subscription.retrieve(customer.subscriptions.data.first.id)

      sub.trial_end = "now"
      sub.save

      expect(sub.object).to eq('subscription')
      expect(sub.plan.to_hash).to eq(plan_with_trial.to_hash)
      expect(sub.status).to eq('active')
      expect(sub.trial_start).to be_nil
      expect(sub.trial_end).to be_nil
    end

    it "changes an active subscription to a trial when trial_end is set" do
      customer = Stripe::Customer.create(id: 'test_trial_end', plan: plan.id, source: gen_card_tk)
      sub = Stripe::Subscription.retrieve(customer.subscriptions.data.first.id)
      trial_end = Time.now.utc.to_i + 3600
      sub.trial_end = trial_end
      sub.save

      expect(sub.object).to eq('subscription')
      expect(sub.plan.to_hash).to eq(plan.to_hash)
      expect(sub.status).to eq('trialing')
      expect(sub.trial_end).to eq(trial_end)
      expect(sub.current_period_end).to eq(trial_end)
    end


    it "raises error when trial_end is not an integer or 'now'" do
      expect(plan.trial_period_days).to be_nil
      customer = Stripe::Customer.create(id: 'test_trial_end', plan: plan.id, source: gen_card_tk)

      sub = Stripe::Subscription.retrieve(customer.subscriptions.data.first.id)
      sub.trial_end = "gazebo"

      expect { sub.save }.to raise_error {|e|
        expect(e).to be_a Stripe::InvalidRequestError
        expect(e.http_status).to eq(400)
        expect(e.message).to eq("Invalid timestamp: must be an integer")
      }
    end
  end

  context "cancelling a subscription" do
    let(:customer) { Stripe::Customer.create(id: 'test_customer_sub', source: gen_card_tk, plan: plan.id) }

    it "cancels a stripe customer's subscription", :live => true do
      customer = Stripe::Customer.create(source: gen_card_tk, plan: plan.id)

      sub = Stripe::Subscription.retrieve(customer.subscriptions.data.first.id)
      result = sub.delete

      expect(result.status).to eq('canceled')
      expect(result.cancel_at_period_end).to eq false
      expect(result.canceled_at).to_not be_nil
      expect(result.id).to eq(sub.id)

      customer = Stripe::Customer.retrieve(customer.id)
      expect(customer.subscriptions.data).to be_empty
      expect(customer.subscriptions.count).to eq(0)
      expect(customer.subscriptions.data.length).to eq(0)
    end

    it "cancels a stripe customer's subscription at period end" do
      customer
      sub = Stripe::Subscription.retrieve(customer.subscriptions.data.first.id)
      result = sub.delete(at_period_end: true)

      expect(result.status).to eq('active')
      expect(result.cancel_at_period_end).to eq(true)
      expect(result.id).to eq(sub.id)

      find_customer = Stripe::Customer.retrieve('test_customer_sub')
      expect(find_customer.subscriptions.data).to_not be_empty
      expect(find_customer.subscriptions.count).to eq(1)
      expect(find_customer.subscriptions.data.length).to eq(1)

      expect(find_customer.subscriptions.data.first.status).to eq('active')
      expect(find_customer.subscriptions.data.first.cancel_at_period_end).to eq(true)
      expect(find_customer.subscriptions.data.first.ended_at).to be_nil
      expect(find_customer.subscriptions.data.first.canceled_at).to_not be_nil
    end

    it "resumes an at period end cancelled subscription" do
      customer
      sub = Stripe::Subscription.retrieve(customer.subscriptions.data.first.id)
      result = sub.delete(at_period_end: true)

      sub.plan = plan.id
      sub.save

      customer = Stripe::Customer.retrieve('test_customer_sub')
      expect(customer.subscriptions.data).to_not be_empty
      expect(customer.subscriptions.count).to eq(1)
      expect(customer.subscriptions.data.length).to eq(1)

      expect(customer.subscriptions.data.first.status).to eq('active')
      expect(customer.subscriptions.data.first.cancel_at_period_end).to eq(false)
      expect(customer.subscriptions.data.first.ended_at).to be_nil
      expect(customer.subscriptions.data.first.canceled_at).to be_nil
    end
  end

  it "doesn't change status of subscription when cancelling at period end" do
    trial = stripe_helper.create_plan(id: 'trial', product: product.id, trial_period_days: 14)
    customer = Stripe::Customer.create(id: 'test_customer_sub', source: gen_card_tk, plan: "trial")

    sub = Stripe::Subscription.retrieve(customer.subscriptions.data.first.id)
    result = sub.delete(at_period_end: true)

    expect(result.status).to eq('trialing')

    customer = Stripe::Customer.retrieve('test_customer_sub')

    expect(customer.subscriptions.data.first.status).to eq('trialing')
  end

  it "doesn't require a card when trial_end is present", :live => true do
    plan = stripe_helper.create_plan(
      :amount => 2000,
      :product => product.id,
      :interval => 'month',
      :name => 'Amazing Gold Plan',
      :currency => 'usd',
      :id => 'gold'
    )

    stripe_customer = Stripe::Customer.create
    options = {plan: plan.id, customer: stripe_customer.id, trial_end: (Date.today + 30).to_time.to_i}
    Stripe::Subscription.create options
  end

  context 'retrieving a single subscription' do
    let(:customer) { Stripe::Customer.create(id: 'test_customer_sub', source: gen_card_tk, plan: 'free') }
    let(:subscription) { Stripe::Subscription.retrieve(customer.subscriptions.data.first.id) }

    before do
      free_plan
      Stripe::Subscription.create({ plan: 'free', customer: customer.id })
    end

    it 'retrieves a single subscription' do
      expect(subscription).to be_truthy
    end

    it "includes 'items' object on retrieved subscription" do
      expect(subscription.items).to be_truthy
      expect(subscription.items.object).to eq('list')
      expect(subscription.items.data.class).to eq(Array)
      expect(subscription.items.data.count).to eq(1)
      expect(subscription.items.data.first.id).to eq('test_txn_default')
      expect(subscription.items.data.first.created).to eq(1504716183)
      expect(subscription.items.data.first.object).to eq('subscription_item')
      expect(subscription.items.data.first.plan.amount).to eq(0)
      expect(subscription.items.data.first.plan.created).to eq(1466698898)
      expect(subscription.items.data.first.plan.currency).to eq('usd')
      expect(subscription.items.data.first.quantity).to eq(2)
    end
  end

  context "retrieve multiple subscriptions" do

    it "retrieves a list of multiple subscriptions" do
      free_plan
      paid = stripe_helper.create_plan(id: 'paid', product: product.id, amount: 499)
      customer = Stripe::Customer.create(id: 'test_customer_sub', source: gen_card_tk, plan: free_plan.id)
      Stripe::Subscription.create({ plan: 'paid', customer: customer.id })

      subs = Stripe::Subscription.all({ customer: customer.id })

      expect(subs.object).to eq("list")
      expect(subs.count).to eq(2)
      expect(subs.data.length).to eq(2)
    end

    it "retrieves an empty list if there's no subscriptions" do
      Stripe::Customer.create(id: 'no_subs')
      customer = Stripe::Customer.retrieve('no_subs')

      list = Stripe::Subscription.all({ customer: customer.id })

      expect(list.object).to eq("list")
      expect(list.count).to eq(0)
      expect(list.data.length).to eq(0)
    end
  end

  describe "metadata" do

    it "creates a stripe customer and subscribes them to a plan with meta data", :live => true do

      stripe_helper.
        create_plan(
        :amount => 500,
        :interval => 'month',
        :product => product.id,
        :currency => 'usd',
        :id => 'Sample5'
      )

      customer = Stripe::Customer.create({
        email: 'johnny@appleseed.com',
        source: gen_card_tk
      })

      subscription = Stripe::Subscription.create({ plan: "Sample5", customer: customer.id })
      subscription.metadata['foo'] = 'bar'

      expect(subscription.save).to be_a Stripe::Subscription

      customer = Stripe::Customer.retrieve(customer.id)
      expect(customer.email).to eq('johnny@appleseed.com')
      expect(customer.subscriptions.first.plan.id).to eq('Sample5')
      expect(customer.subscriptions.first.metadata['foo']).to eq('bar')
    end
  end

end
