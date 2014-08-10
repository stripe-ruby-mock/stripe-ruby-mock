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

  it "creates a single card with a generated card token", :live => true do
    customer = Stripe::Customer.create
    expect(customer.cards.count).to eq 0

    customer.cards.create :card => stripe_helper.generate_card_token
    # Yes, stripe-ruby does not actually add the new card to the customer instance
    expect(customer.cards.count).to eq 0

    customer2 = Stripe::Customer.retrieve(customer.id)
    expect(customer2.cards.count).to eq 1
    expect(customer2.default_card).to eq customer2.cards.first.id
  end

  context "retrieval and deletion" do
    let!(:customer) { Stripe::Customer.create(id: 'test_customer_sub') }
    let!(:card_token) { StripeMock.generate_card_token(last4: "1123", exp_month: 11, exp_year: 2099) }
    let!(:card) { customer.cards.create(card: card_token) }

    it "retrieves a customers card" do
      retrieved = customer.cards.retrieve(card.id)
      expect(retrieved.to_s).to eq(card.to_s)
    end

    it "deletes a customers card" do
      card.delete
      retrieved_cus = Stripe::Customer.retrieve(customer.id)
      expect(retrieved_cus.cards.data).to be_empty
    end

    it "updates the default card if deleted"

  end

  context "update card" do
    let!(:customer) { Stripe::Customer.create(id: 'test_customer_sub') }
    let!(:card_token) { StripeMock.generate_card_token(last4: "1123", exp_month: 11, exp_year: 2099) }
    let!(:card) { customer.cards.create(card: card_token) }

    it "updates the card" do
      exp_month = 10
      exp_year = 2098

      card.exp_month = exp_month
      card.exp_year = exp_year
      card.save

      retrieved = customer.cards.retrieve(card.id)

      expect(retrieved.exp_month).to eq(exp_month)
      expect(retrieved.exp_year).to eq(exp_year)
    end
  end

  context "retrieve multiple cards" do

    it "retrieves a list of multiple cards" do
      customer = Stripe::Customer.create(id: 'test_customer_card')

      card_token = StripeMock.generate_card_token(last4: "1123", exp_month: 11, exp_year: 2099)
      card1 = customer.cards.create(card: card_token)
      card_token = StripeMock.generate_card_token(last4: "1124", exp_month: 12, exp_year: 2098)
      card2 = customer.cards.create(card: card_token)

      customer = Stripe::Customer.retrieve('test_customer_card')

      list = customer.cards.all

      expect(list.object).to eq("list")
      expect(list.count).to eq(2)
      expect(list.data.length).to eq(2)

      expect(list.data.first.object).to eq("card")
      expect(list.data.first.to_hash).to eq(card1.to_hash)

      expect(list.data.last.object).to eq("card")
      expect(list.data.last.to_hash).to eq(card2.to_hash)
    end

    it "retrieves an empty list if there's no subscriptions" do
      Stripe::Customer.create(id: 'no_cards')
      customer = Stripe::Customer.retrieve('no_cards')

      list = customer.cards.all

      expect(list.object).to eq("list")
      expect(list.count).to eq(0)
      expect(list.data.length).to eq(0)
    end
  end

end
