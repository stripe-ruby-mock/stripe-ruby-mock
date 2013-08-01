require 'spec_helper'

shared_examples 'Card Token Mocking' do

  it "generates and reads a card token for create customer" do
    card_token = StripeMock.generate_card_token(last4: "9191", exp_month: 99, exp_year: 3005)

    cus = Stripe::Customer.create(card: card_token)
    card = cus.cards.data.first
    expect(card.last4).to eq("9191")
    expect(card.exp_month).to eq(99)
    expect(card.exp_year).to eq(3005)
  end

  it "generated and reads a card token for update customer" do
    card_token = StripeMock.generate_card_token(last4: "1133", exp_month: 11, exp_year: 2099)

    cus = Stripe::Customer.create()
    cus.card = card_token
    cus.save

    card = cus.cards.data.first
    expect(card.last4).to eq("1133")
    expect(card.exp_month).to eq(11)
    expect(card.exp_year).to eq(2099)
  end

end
