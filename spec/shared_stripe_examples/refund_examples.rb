require 'spec_helper'

shared_examples 'Refund API' do

  it "creates a stripe refund with the charge ID" do
    charge = Stripe::Charge.create(
      amount: 999,
      currency: 'USD',
      card: 'card_token_abcde',
      description: 'card charge'
    )
    refund = charge.refund

    expect(charge.id).to match(/^test_ch/)
    expect(refund.id).to eq(charge.id)
  end

  it "creates a stripe refund with a different balance transaction than the charge" do
    charge = Stripe::Charge.create(
      amount: 999,
      currency: 'USD',
      card: 'card_token_abcde',
      description: 'card charge'
    )
    refund = charge.refund

    expect(charge.balance_transaction).not_to eq(refund.refunds.first.balance_transaction)
  end
end
