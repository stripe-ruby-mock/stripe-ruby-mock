require 'spec_helper'

shared_examples 'Customer API' do

  it "creates a stripe customer with a default card" do
    customer = Stripe::Customer.create({
      email: 'johnny@appleseed.com',
      card: 'some_card_token',
      description: "a description"
    })
    expect(customer.id).to match(/^test_cus/)
    expect(customer.email).to eq('johnny@appleseed.com')
    expect(customer.description).to eq('a description')

    expect(customer.cards.count).to eq(1)
    expect(customer.cards.data.length).to eq(1)
    expect(customer.default_card).to_not be_nil
    expect(customer.default_card).to eq customer.cards.data.first.id

    expect { customer.card }.to raise_error
  end

  it "creates a stripe customer without a card" do
    customer = Stripe::Customer.create({
      email: 'cardless@appleseed.com',
      description: "no card"
    })
    expect(customer.id).to match(/^test_cus/)
    expect(customer.email).to eq('cardless@appleseed.com')
    expect(customer.description).to eq('no card')

    expect(customer.cards.count).to eq(0)
    expect(customer.cards.data.length).to eq(0)
    expect(customer.default_card).to be_nil
  end

  it 'creates a customer with a plan' do
    plan = Stripe::Plan.create(id: 'silver')
    customer = Stripe::Customer.create(id: 'test_cus_plan', card: 'tk', :plan => 'silver')

    customer = Stripe::Customer.retrieve('test_cus_plan')
    expect(customer.subscription).to_not be_nil
    expect(customer.subscription.plan.id).to eq('silver')
    expect(customer.subscription.customer).to eq(customer.id)
  end

  it 'cannot create a customer with a plan that does not exist' do
    expect {
      customer = Stripe::Customer.create(id: 'test_cus_no_plan', card: 'tk', :plan => 'non-existant')
    }.to raise_error {|e|
      expect(e).to be_a(Stripe::InvalidRequestError)
      expect(e.message).to eq('No such plan: non-existant')
    }
  end

  it 'cannot create a customer with an exsting plan, but no card token' do
    plan = Stripe::Plan.create(id: 'p')
    expect {
      customer = Stripe::Customer.create(id: 'test_cus_no_plan', :plan => 'p')
    }.to raise_error {|e|
      expect(e).to be_a(Stripe::InvalidRequestError)
      expect(e.message).to eq('You must supply a valid card')
    }
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
    expect(customer.default_card).to eq(original.default_card)
    expect(customer.subscription).to be_nil
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
    expect(all.length).to eq(2)
    all.map(&:email).should include('one@one.com', 'two@two.com')
  end

  it "updates a stripe customer" do
    original = Stripe::Customer.create(id: 'test_customer_update')
    email = original.email

    original.description = 'new desc'
    original.save

    expect(original.email).to eq(email)
    expect(original.description).to eq('new desc')

    customer = Stripe::Customer.retrieve("test_customer_update")
    expect(customer.email).to eq(original.email)
    expect(customer.description).to eq('new desc')
  end

  it "updates a stripe customer's card" do
    original = Stripe::Customer.create(id: 'test_customer_update', card: 'token')
    card = original.cards.data.first
    expect(original.default_card).to eq(card.id)
    expect(original.cards.count).to eq(1)

    original.card = 'new_token'
    original.save

    new_card = original.cards.data.first
    expect(original.cards.count).to eq(1)
    expect(original.default_card).to eq(new_card.id)

    expect(new_card.id).to_not eq(card.id)
  end

  it "deletes a customer" do
    customer = Stripe::Customer.create(id: 'test_customer_sub')
    customer = customer.delete
    expect(customer.deleted).to be_true
  end

  context "With strict mode toggled off" do

    before { StripeMock.toggle_strict(false) }

    it "retrieves a stripe customer with an id that doesn't exist" do
      customer = Stripe::Customer.retrieve('test_customer_x')
      expect(customer.id).to eq('test_customer_x')
      expect(customer.email).to_not be_nil
      expect(customer.description).to_not be_nil
    end
  end

end
