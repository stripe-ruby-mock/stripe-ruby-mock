require 'spec_helper'

shared_examples 'Charge API' do

  it "requires a valid card token", :live => true do
    expect {
      charge = Stripe::Charge.create(
        amount: 99,
        currency: 'usd',
        card: 'bogus_card_token'
      )
    }.to raise_error(Stripe::InvalidRequestError, /Invalid token id/)
  end

  it "creates a stripe charge item with a card token" do
    charge = Stripe::Charge.create(
      amount: 999,
      currency: 'USD',
      card: stripe_helper.generate_card_token,
      description: 'card charge'
    )

    expect(charge.id).to match(/^test_ch/)
    expect(charge.amount).to eq(999)
    expect(charge.description).to eq('card charge')
    expect(charge.captured).to eq(true)
  end


  it "creates a stripe charge item with a customer and card id" do
    customer = Stripe::Customer.create({
      email: 'johnny@appleseed.com',
      card: stripe_helper.generate_card_token(number: '4012888888881881'),
      description: "a description"
    })

    expect(customer.cards.data.length).to eq(1)
    expect(customer.cards.data[0].id).not_to be_nil
    expect(customer.cards.data[0].last4).to eq('1881')

    card   = customer.cards.data[0]
    charge = Stripe::Charge.create(
      amount: 999,
      currency: 'USD',
      customer: customer.id,
      card: card.id,
      description: 'a charge with a specific card'
    )

    expect(charge.id).to match(/^test_ch/)
    expect(charge.amount).to eq(999)
    expect(charge.description).to eq('a charge with a specific card')
    expect(charge.captured).to eq(true)
    expect(charge.card.last4).to eq('1881')
  end


  it "stores a created stripe charge in memory" do
    charge = Stripe::Charge.create({
      amount: 333,
      currency: 'USD',
      card: stripe_helper.generate_card_token
    })
    charge2 = Stripe::Charge.create({
      amount: 777,
      currency: 'USD',
      card: stripe_helper.generate_card_token
    })
    data = test_data_source(:charges)
    expect(data[charge.id]).to_not be_nil
    expect(data[charge.id][:amount]).to eq(333)

    expect(data[charge2.id]).to_not be_nil
    expect(data[charge2.id][:amount]).to eq(777)
  end

  it "retrieves a stripe charge" do
    original = Stripe::Charge.create({
      amount: 777,
      currency: 'USD',
      card: stripe_helper.generate_card_token
    })
    charge = Stripe::Charge.retrieve(original.id)

    expect(charge.id).to eq(original.id)
    expect(charge.amount).to eq(original.amount)
  end

  it "cannot retrieve a charge that doesn't exist" do
    expect { Stripe::Charge.retrieve('nope') }.to raise_error {|e|
      expect(e).to be_a Stripe::InvalidRequestError
      expect(e.param).to eq('charge')
      expect(e.http_status).to eq(404)
    }
  end

  it "creates a unique balance transaction" do
    charge1 = Stripe::Charge.create(
      amount: 999,
      currency: 'USD',
      card: stripe_helper.generate_card_token,
      description: 'card charge'
    )

    charge2 = Stripe::Charge.create(
      amount: 999,
      currency: 'USD',
      card: stripe_helper.generate_card_token,
      description: 'card charge'
    )

    expect(charge1.balance_transaction).not_to eq(charge2.balance_transaction)
  end

  context "retrieving a list of charges" do
    before do
      @customer = Stripe::Customer.create(email: 'johnny@appleseed.com')
      @charge = Stripe::Charge.create(customer: @customer.id)
      @charge2 = Stripe::Charge.create
    end

    it "stores charges for a customer in memory" do
      expect(@customer.charges.data.map(&:id)).to eq([@charge.id])
    end

    it "stores all charges in memory" do
      expect(Stripe::Charge.all.data.map(&:id)).to eq([@charge.id, @charge2.id])
    end

    it "defaults count to 10 charges" do
      11.times { Stripe::Charge.create }
      expect(Stripe::Charge.all.data.count).to eq(10)
    end

    context "when passing limit" do
      it "gets that many charges" do
        expect(Stripe::Charge.all(limit: 1).count).to eq(1)
      end
    end
  end

  describe 'captured status value' do
    it "reports captured by default" do
      charge = Stripe::Charge.create({
        amount: 777,
        currency: 'USD',
        card: stripe_helper.generate_card_token
      })

      expect(charge.captured).to eq(true)
    end

    it "reports captured if capture requested" do
      charge = Stripe::Charge.create({
        amount: 777,
        currency: 'USD',
        card: stripe_helper.generate_card_token,
        capture: true
      })

      expect(charge.captured).to eq(true)
    end

    it "reports not captured if capture: false requested" do
      charge = Stripe::Charge.create({
        amount: 777,
        currency: 'USD',
        card: stripe_helper.generate_card_token,
        capture: false
      })

      expect(charge.captured).to eq(false)
    end
  end

  describe "two-step charge (auth, then capture)" do
    it "changes captured status upon #capture" do
      charge = Stripe::Charge.create({
        amount: 777,
        currency: 'USD',
        card: stripe_helper.generate_card_token,
        capture: false
      })

      returned_charge = charge.capture
      expect(charge.captured).to eq(true)
      expect(returned_charge.id).to eq(charge.id)
      expect(returned_charge.captured).to eq(true)
    end

    it "captures with specified amount" do
      charge = Stripe::Charge.create({
        amount: 777,
        currency: 'USD',
        card: stripe_helper.generate_card_token,
        capture: false
      })

      returned_charge = charge.capture({ amount: 677 })
      expect(charge.captured).to eq(true)
      expect(returned_charge.amount_refunded).to eq(100)
      expect(returned_charge.id).to eq(charge.id)
      expect(returned_charge.captured).to eq(true)
    end
  end

end
