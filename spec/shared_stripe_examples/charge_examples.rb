require 'spec_helper'

shared_examples 'Charge API' do

  it "creates a stripe charge item with a card token" do
    charge = Stripe::Charge.create(
      amount: 999,
      currency: 'USD',
      card: 'card_token_abcde',
      description: 'card charge'
    )

    expect(charge.id).to match(/^test_ch/)
    expect(charge.amount).to eq(999)
    expect(charge.description).to eq('card charge')
    expect(charge.captured).to eq(true)
  end


  it "stores a created stripe charge in memory" do
    charge = Stripe::Charge.create({
      amount: 333,
      currency: 'USD',
      card: 'card_token_333'
    })
    charge2 = Stripe::Charge.create({
      amount: 777,
      currency: 'USD',
      card: 'card_token_777'
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
      card: 'card_token_abc'
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


  context "With strict mode toggled off" do

    before { StripeMock.toggle_strict(false) }

    it "retrieves a stripe charge with an id that doesn't exist" do
      charge = Stripe::Charge.retrieve('test_charge_x')
      expect(charge.id).to eq('test_charge_x')
      expect(charge.amount).to_not be_nil
      expect(charge.card).to_not be_nil
    end
  end


  describe 'captured status value' do
    it "reports captured by default" do
      charge = Stripe::Charge.create({
        amount: 777,
        currency: 'USD',
        card: 'card_token_abc'
      })

      expect(charge.captured).to be_true
    end

    it "reports captured if capture requested" do
      charge = Stripe::Charge.create({
        amount: 777,
        currency: 'USD',
        card: 'card_token_abc',
        capture: true
      })

      expect(charge.captured).to be_true
    end

    it "reports not captured if capture: false requested" do
      charge = Stripe::Charge.create({
        amount: 777,
        currency: 'USD',
        card: 'card_token_abc',
        capture: false
      })

      expect(charge.captured).to be_false
    end
  end

  describe "two-step charge (auth, then capture)" do
    it "changes captured status upon #capture" do
      charge = Stripe::Charge.create({
        amount: 777,
        currency: 'USD',
        card: 'card_token_abc',
        capture: false
      })

      returned_charge = charge.capture
      expect(charge.captured).to be_true
      expect(returned_charge.id).to eq(charge.id)
      expect(returned_charge.captured).to be_true
    end
  end
end
