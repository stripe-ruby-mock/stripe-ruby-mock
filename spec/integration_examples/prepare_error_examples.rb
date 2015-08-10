require 'spec_helper'

shared_examples 'Card Error Prep' do

  it 'prepares a card error' do
    StripeMock.prepare_card_error(:card_declined, :new_charge)
    cus = Stripe::Customer.create(email: 'alice@example.com')
    expect { Stripe::Charge.create({
      amount: 900,
      currency: 'usd',
      source: StripeMock.generate_card_token(number: '4242424242424241', brand: 'Visa'),
      description: 'hello'
      })
    }.to raise_error(Stripe::CardError, 'The card was declined')
  end
end
