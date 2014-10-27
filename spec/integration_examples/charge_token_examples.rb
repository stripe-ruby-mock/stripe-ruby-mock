require 'spec_helper'

shared_examples 'Charging with Tokens' do

  describe "With OAuth" do

    before do
      @cus = Stripe::Customer.create(
        :card => stripe_helper.generate_card_token({ :number => '4242424242424242', :brand => 'Visa' })
      )

      @card_token = Stripe::Token.create({
        :customer => @cus.id,
        :card => @cus.cards.first.id
      }, ENV['STRIPE_TEST_OAUTH_ACCESS_TOKEN'])
    end

    it "creates with an oauth access token", :oauth => true do
      charge = Stripe::Charge.create({
        :amount => 1099,
        :currency => 'usd',
        :card => @card_token.id
      }, ENV['STRIPE_TEST_OAUTH_ACCESS_TOKEN'])

      expect(charge.card.id).to_not eq @cus.cards.first.id
      expect(charge.card.fingerprint).to eq @cus.cards.first.fingerprint
      expect(charge.card.last4).to eq '4242'
      expect(charge.card.brand).to eq 'Visa'

      retrieved_charge = Stripe::Charge.retrieve(charge.id)

      expect(retrieved_charge.card.id).to_not eq @cus.cards.first.id
      expect(retrieved_charge.card.fingerprint).to eq @cus.cards.first.fingerprint
      expect(retrieved_charge.card.last4).to eq '4242'
      expect(retrieved_charge.card.brand).to eq 'Visa'
    end

    it "throws an error when the card is not an id", :oauth => true do
      expect {
        charge = Stripe::Charge.create({
          :amount => 1099,
          :currency => 'usd',
          :card => @card_token
        }, ENV['STRIPE_TEST_OAUTH_ACCESS_TOKEN'])
      }.to raise_error(Stripe::InvalidRequestError, /Invalid token id/)
    end
  end

end
