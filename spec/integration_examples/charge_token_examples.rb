require 'spec_helper'

shared_examples 'Charging with Tokens' do

  it "creates with an oauth access token", :oauth => true do
    cus = Stripe::Customer.create(
      :card => stripe_helper.generate_card_token({ :number => '4242424242424242', :brand => 'Visa' })
    )

    card_token = Stripe::Token.create({
      :customer => cus.id,
      :card => cus.cards.first.id
    }, ENV['STRIPE_TEST_OAUTH_ACCESS_TOKEN'])

    charge = Stripe::Charge.create({
      :amount => 1099,
      :currency => 'usd',
      :card => card_token.id
    }, ENV['STRIPE_TEST_OAUTH_ACCESS_TOKEN'])
  end

end
