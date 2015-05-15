require 'spec_helper'

shared_examples 'Customer API' do

  def gen_card_tk
    stripe_helper.generate_card_token
  end

  it "creates a stripe customer with a default card" do
    customer = Stripe::Customer.create({
      email: 'johnny@appleseed.com',
      source: gen_card_tk,
      description: "a description"
    })
    expect(customer.id).to match(/^test_cus/)
    expect(customer.email).to eq('johnny@appleseed.com')
    expect(customer.description).to eq('a description')

    expect(customer.sources.count).to eq(1)
    expect(customer.sources.data.length).to eq(1)
    expect(customer.default_source).to_not be_nil
    expect(customer.default_source).to eq customer.sources.data.first.id

    expect { customer.source }.to raise_error
  end

  it "creates a stripe customer without a card" do
    customer = Stripe::Customer.create({
      email: 'cardless@appleseed.com',
      description: "no card"
    })
    expect(customer.id).to match(/^test_cus/)
    expect(customer.email).to eq('cardless@appleseed.com')
    expect(customer.description).to eq('no card')

    expect(customer.sources.count).to eq(0)
    expect(customer.sources.data.length).to eq(0)
    expect(customer.default_source).to be_nil
  end

  it 'creates a stripe customer with a dictionary of card values', live: true do
    customer = Stripe::Customer.create(source: {
                                           object: 'card',
                                           number: '4242424242424242',
                                           exp_month: 12,
                                           exp_year: 2024
                                       },
                                       email: 'blah@blah.com')

    expect(customer).to be_a Stripe::Customer
    expect(customer.id).to match(/cus_/)
    expect(customer.email).to eq 'blah@blah.com'
    expect(customer.sources.data.first.object).to eq 'card'
    expect(customer.sources.data.first.last4).to eq '4242'
    expect(customer.sources.data.first.exp_month).to eq 12
    expect(customer.sources.data.first.exp_year).to eq 2024
  end

  it 'creates a customer with a plan' do
    plan = stripe_helper.create_plan(id: 'silver')
    customer = Stripe::Customer.create(id: 'test_cus_plan', source: gen_card_tk, :plan => 'silver')

    customer = Stripe::Customer.retrieve('test_cus_plan')
    expect(customer.subscriptions.count).to eq(1)
    expect(customer.subscriptions.data.length).to eq(1)

    expect(customer.subscriptions).to_not be_nil
    expect(customer.subscriptions.first.plan.id).to eq('silver')
    expect(customer.subscriptions.first.customer).to eq(customer.id)
  end

  it "creates a customer with a plan (string/symbol agnostic)" do
    plan = stripe_helper.create_plan(id: 'string_id')
    customer = Stripe::Customer.create(id: 'test_cus_plan', source: gen_card_tk, :plan => :string_id)

    customer = Stripe::Customer.retrieve('test_cus_plan')
    expect(customer.subscriptions.first.plan.id).to eq('string_id')

    plan = stripe_helper.create_plan(:id => :sym_id)
    customer = Stripe::Customer.create(id: 'test_cus_plan', source: gen_card_tk, :plan => 'sym_id')

    customer = Stripe::Customer.retrieve('test_cus_plan')
    expect(customer.subscriptions.first.plan.id).to eq('sym_id')
  end

  context "create customer" do

    it "with a trial when trial_end is set" do
      plan = stripe_helper.create_plan(id: 'no_trial', amount: 999)
      trial_end = Time.now.utc.to_i + 3600
      customer = Stripe::Customer.create(id: 'test_cus_trial_end', source: gen_card_tk, plan: 'no_trial', trial_end: trial_end)

      customer = Stripe::Customer.retrieve('test_cus_trial_end')
      expect(customer.subscriptions.count).to eq(1)
      expect(customer.subscriptions.data.length).to eq(1)

      expect(customer.subscriptions).to_not be_nil
      expect(customer.subscriptions.first.plan.id).to eq('no_trial')
      expect(customer.subscriptions.first.status).to eq('trialing')
      expect(customer.subscriptions.first.current_period_end).to eq(trial_end)
      expect(customer.subscriptions.first.trial_end).to eq(trial_end)
    end

    it 'overrides trial period length when trial_end is set' do
      plan = stripe_helper.create_plan(id: 'silver', amount: 999, trial_period_days: 14)
      trial_end = Time.now.utc.to_i + 3600
      customer = Stripe::Customer.create(id: 'test_cus_trial_end', source: gen_card_tk, plan: 'silver', trial_end: trial_end)

      customer = Stripe::Customer.retrieve('test_cus_trial_end')
      expect(customer.subscriptions.count).to eq(1)
      expect(customer.subscriptions.data.length).to eq(1)

      expect(customer.subscriptions).to_not be_nil
      expect(customer.subscriptions.first.plan.id).to eq('silver')
      expect(customer.subscriptions.first.current_period_end).to eq(trial_end)
      expect(customer.subscriptions.first.trial_end).to eq(trial_end)
    end

    it "returns no trial when trial_end is set to 'now'" do
      plan = stripe_helper.create_plan(id: 'silver', amount: 999, trial_period_days: 14)
      customer = Stripe::Customer.create(id: 'test_cus_trial_end', source: gen_card_tk, plan: 'silver', trial_end: "now")

      customer = Stripe::Customer.retrieve('test_cus_trial_end')
      expect(customer.subscriptions.count).to eq(1)
      expect(customer.subscriptions.data.length).to eq(1)

      expect(customer.subscriptions).to_not be_nil
      expect(customer.subscriptions.first.plan.id).to eq('silver')
      expect(customer.subscriptions.first.status).to eq('active')
      expect(customer.subscriptions.first.trial_start).to be_nil
      expect(customer.subscriptions.first.trial_end).to be_nil
    end

    it "returns an error if trial_end is set to a past time" do
      plan = stripe_helper.create_plan(id: 'silver', amount: 999)
      expect {
        Stripe::Customer.create(id: 'test_cus_trial_end', source: gen_card_tk, plan: 'silver', trial_end: Time.now.utc.to_i - 3600)
      }.to raise_error {|e|
        expect(e).to be_a(Stripe::InvalidRequestError)
        expect(e.message).to eq('Invalid timestamp: must be an integer Unix timestamp in the future')
      }
    end

    it "returns an error if trial_end is set without a plan" do
      expect {
        Stripe::Customer.create(id: 'test_cus_trial_end', source: gen_card_tk, trial_end: "now")
      }.to raise_error {|e|
        expect(e).to be_a(Stripe::InvalidRequestError)
        expect(e.message).to eq('Received unknown parameter: trial_end')
      }
    end

  end

  it 'cannot create a customer with a plan that does not exist' do
    expect {
      customer = Stripe::Customer.create(id: 'test_cus_no_plan', source: gen_card_tk, :plan => 'non-existant')
    }.to raise_error {|e|
      expect(e).to be_a(Stripe::InvalidRequestError)
      expect(e.message).to eq('No such plan: non-existant')
    }
  end

  it 'cannot create a customer with an existing plan, but no card token' do
    plan = stripe_helper.create_plan(id: 'p')
    expect {
      customer = Stripe::Customer.create(id: 'test_cus_no_plan', :plan => 'p')
    }.to raise_error {|e|
      expect(e).to be_a(Stripe::InvalidRequestError)
      expect(e.message).to eq('You must supply a valid card')
    }
  end

  it 'creates a customer with a coupon discount' do
    coupon = Stripe::Coupon.create(id: "10PERCENT", duration: 'once')

    customer =
      Stripe::Customer.create(id: 'test_cus_coupon', coupon: '10PERCENT')

    customer = Stripe::Customer.retrieve('test_cus_coupon')
    expect(customer.discount).to_not be_nil
    expect(customer.discount.coupon).to_not be_nil
  end

  it 'cannot create a customer with a coupon that does not exist' do
    expect{
      customer = Stripe::Customer.create(id: 'test_cus_no_coupon', coupon: '5OFF')
    }.to raise_error {|e|
      expect(e).to be_a(Stripe::InvalidRequestError)
      expect(e.message).to eq('No such coupon: 5OFF')
    }
  end

  it "stores a created stripe customer in memory" do
    customer = Stripe::Customer.create({
      email: 'johnny@appleseed.com',
      source: gen_card_tk
    })
    customer2 = Stripe::Customer.create({
      email: 'bob@bobbers.com',
      source: gen_card_tk
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
      source: gen_card_tk
    })
    customer = Stripe::Customer.retrieve(original.id)

    expect(customer.id).to eq(original.id)
    expect(customer.email).to eq(original.email)
    expect(customer.default_source).to eq(original.default_source)
    expect(customer.subscriptions.count).to eq(0)
    expect(customer.subscriptions.data).to be_empty
  end

  it "cannot retrieve a customer that doesn't exist" do
    expect { Stripe::Customer.retrieve('nope') }.to raise_error {|e|
      expect(e).to be_a Stripe::InvalidRequestError
      expect(e.param).to eq('customer')
      expect(e.http_status).to eq(404)
    }
  end

  it "retrieves all customers" do
    Stripe::Customer.create({ email: 'one@one.com' })
    Stripe::Customer.create({ email: 'two@two.com' })

    all = Stripe::Customer.all
    expect(all.count).to eq(2)
    expect(all.map &:email).to include('one@one.com', 'two@two.com')
  end

  it "updates a stripe customer" do
    original = Stripe::Customer.create(id: 'test_customer_update')
    email = original.email

    coupon = Stripe::Coupon.create(id: "10PERCENT", duration: 'once')
    original.description = 'new desc'
    original.coupon      = coupon.id
    original.save

    expect(original.email).to eq(email)
    expect(original.description).to eq('new desc')
    expect(original.discount.coupon).to be_a Stripe::Coupon

    customer = Stripe::Customer.retrieve("test_customer_update")
    expect(customer.email).to eq(original.email)
    expect(customer.description).to eq('new desc')
    expect(customer.discount.coupon).to be_a Stripe::Coupon
  end

  it "updates a stripe customer's card" do
    original = Stripe::Customer.create(id: 'test_customer_update', source: gen_card_tk)
    card = original.sources.data.first
    expect(original.default_source).to eq(card.id)
    expect(original.sources.count).to eq(1)

    original.source = gen_card_tk
    original.save

    new_card = original.sources.data.last
    expect(original.sources.count).to eq(1)
    expect(original.default_source).to_not eq(card.id)

    expect(new_card.id).to_not eq(card.id)
  end

  it "deletes a customer" do
    customer = Stripe::Customer.create(id: 'test_customer_sub')
    customer = customer.delete
    expect(customer.deleted).to eq(true)
  end
end
