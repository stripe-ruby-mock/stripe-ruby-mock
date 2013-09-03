require 'spec_helper'

shared_examples 'Card API' do
  it 'creates/returns a card when using customer.cards.create given a card token' do
    customer = Stripe::Customer.create(id: 'test_customer_sub')
    card_token = StripeMock.generate_card_token(last4: "1123", exp_month: 11, exp_year: 2099)
    card = customer.cards.create(card: card_token)

    expect(card.customer).to eq('test_customer_sub')
    expect(card.last4).to eq("1123")
    expect(card.exp_month).to eq(11)
    expect(card.exp_year).to eq(2099)

    customer = Stripe::Customer.retrieve('test_customer_sub')
    expect(customer.cards.count).to eq(1)
    card = customer.cards.data.first
    expect(card.customer).to eq('test_customer_sub')
    expect(card.last4).to eq("1123")
    expect(card.exp_month).to eq(11)
    expect(card.exp_year).to eq(2099)
  end

  it 'creates/returns a card when using customer.cards.create given card params' do
    customer = Stripe::Customer.create(id: 'test_customer_sub')
    card = customer.cards.create(card: {
      number: '4242424242424242',
      exp_month: '11',
      exp_year: '3031',
      cvc: '123'
    })

    expect(card.customer).to eq('test_customer_sub')
    expect(card.last4).to eq("4242")
    expect(card.exp_month).to eq(11)
    expect(card.exp_year).to eq(3031)

    customer = Stripe::Customer.retrieve('test_customer_sub')
    expect(customer.cards.count).to eq(1)
    card = customer.cards.data.first
    expect(card.customer).to eq('test_customer_sub')
    expect(card.last4).to eq("4242")
    expect(card.exp_month).to eq(11)
    expect(card.exp_year).to eq(3031)
  end

  it 'create does not change the customers default card' do
    customer = Stripe::Customer.create(id: 'test_customer_sub')
    card_token = StripeMock.generate_card_token(last4: "1123", exp_month: 11, exp_year: 2099)
    card = customer.cards.create(card: card_token)

    customer = Stripe::Customer.retrieve('test_customer_sub')
    expect(customer.default_card).to be_nil
  end
end
