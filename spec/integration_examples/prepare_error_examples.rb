require 'spec_helper'

shared_examples 'Card Error Prep' do

  # it "prepares a card error" do
  #   StripeMock.prepare_card_error(:card_declined, :new_charge)
  #   cus = Stripe::Customer.create :email => 'alice@bob.com',
  #                                 :card => stripe_helper.generate_card_token({ :number => '4242424242424242', :brand => 'Visa' })

  #   expect {
  #     charge = Stripe::Charge.create({
  #       :amount => 999, :currency => 'usd',
  #       :customer => cus, :card => cus.cards.first,
  #       :description => 'hello'
  #     })
  #   }.to raise_error Stripe::CardError
  # end
end
