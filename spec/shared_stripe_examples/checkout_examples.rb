require 'spec_helper'

shared_examples 'Checkout API' do

  it "creates a stripe checkout session" do
    session = Stripe::Checkout::Session.create({
      payment_method_types: ['card'],
      line_items: [{
        name: 'T-shirt',
        quantity: 1,
        amount: 500,
        currency: 'usd',
      }],
    })
    expect(session.id).to match(/^test_cs/)
    expect(session.line_items.count).to eq(1)
  end
  
end
