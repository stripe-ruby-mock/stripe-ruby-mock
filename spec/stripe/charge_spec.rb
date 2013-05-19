require 'spec_helper'

describe 'Charge API' do

  before { StripeMock.start }
  after  { StripeMock.stop }

  it "creates a stripe charge item with a card token" do
    charge = Stripe::Charge.create(
      amount: 999,
      currency: 'USD',
      card: 'card_token_abcde',
      description: 'card charge'
    )

    expect(charge.amount).to eq(999)
    expect(charge.description).to eq('card charge')
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
    data = StripeMock.instance.charges
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


  it "retrieves a stripe charge with an id that doesn't exist" do
    charge = Stripe::Charge.retrieve('test_charge_x')
    expect(charge.id).to eq('test_charge_x')
    expect(charge.amount).to_not be_nil
    expect(charge.card).to_not be_nil
  end

end
