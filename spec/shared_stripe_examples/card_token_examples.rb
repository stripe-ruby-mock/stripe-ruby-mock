require 'spec_helper'

shared_examples 'Card Token Mocking' do

  it "generates a card token" do
    card_token = StripeMock.generate_card_token(last4: "9191", exp_month: 99, exp_year: 3005)

    cus = Stripe::Customer.create(card: card_token)
    card = cus.cards.data.first
    expect(card.last4).to eq("9191")
    expect(card.exp_month).to eq(99)
    expect(card.exp_year).to eq(3005)
  end

end
