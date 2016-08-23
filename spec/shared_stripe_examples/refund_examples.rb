require 'spec_helper'

shared_examples 'Refund API' do

  it "refunds a stripe charge item" do
    charge = Stripe::Charge.create(
      amount: 999,
      currency: 'USD',
      card: stripe_helper.generate_card_token,
      description: 'card charge'
    )

    charge = charge.refund(amount: 999)

    expect(charge.refunded).to eq(true)
    expect(charge.refunds.data.first.amount).to eq(999)
    expect(charge.amount_refunded).to eq(999)
  end

  it "creates a stripe refund with the charge ID", :live => true do
    charge = Stripe::Charge.create(
      amount: 999,
      currency: 'USD',
      card: stripe_helper.generate_card_token,
      description: 'card charge'
    )
    refund = charge.refund

    expect(charge.id).to match(/^(test_)?ch/)
    expect(refund.id).to eq(charge.id)
  end

  it "creates a stripe refund with a refund ID" do
    charge = Stripe::Charge.create(
      amount: 999,
      currency: 'USD',
      card: stripe_helper.generate_card_token,
      description: 'card charge'
    )
    refund = charge.refund

    expect(refund.refunds.data.count).to eq 1
    expect(refund.refunds.data.first.id).to match(/^test_re/)
  end

  it "creates a stripe refund with a status" do
    charge = Stripe::Charge.create(
      amount: 999,
      currency: 'USD',
      card: stripe_helper.generate_card_token,
      description: 'card charge'
    )
    refund = charge.refund

    expect(refund.refunds.data.count).to eq 1
    expect(refund.refunds.data.first.status).to eq("succeeded")
  end
  
  it "creates a stripe refund with a different balance transaction than the charge" do
    charge = Stripe::Charge.create(
      amount: 999,
      currency: 'USD',
      card: stripe_helper.generate_card_token,
      description: 'card charge'
    )
    refund = charge.refund

    expect(charge.balance_transaction).not_to eq(refund.refunds.data.first.balance_transaction)
  end

  it "creates a refund off a charge", :live => true do
    original = Stripe::Charge.create(amount: 555, currency: 'USD', card: stripe_helper.generate_card_token)

    charge = Stripe::Charge.retrieve(original.id)

    refund = charge.refunds.create(amount: 555)
    expect(refund.amount).to eq 555
    expect(refund.charge).to eq charge.id
  end

  it "handles multiple refunds", :live => true do
    original = Stripe::Charge.create(amount: 1100, currency: 'USD', card: stripe_helper.generate_card_token)

    charge = Stripe::Charge.retrieve(original.id)

    refund_1 = charge.refunds.create(amount: 300)
    expect(refund_1.amount).to eq 300
    expect(refund_1.charge).to eq charge.id

    refund_2 = charge.refunds.create(amount: 400)
    expect(refund_2.amount).to eq 400
    expect(refund_2.charge).to eq charge.id

    expect(charge.refunds.count).to eq 0
    expect(charge.refunds.total_count).to eq 0
    expect(charge.amount_refunded).to eq 0

    charge = Stripe::Charge.retrieve(original.id)
    expect(charge.refunds.count).to eq 2
    expect(charge.refunds.total_count).to eq 2
    expect(charge.amount_refunded).to eq 700
  end

  it 'returns Stripe::Refund object', live: true do
    charge = Stripe::Charge.create(
        amount: 999,
        currency: 'USD',
        card: stripe_helper.generate_card_token,
        description: 'card charge'
    )
    refund = Stripe::Refund.create(
        charge: charge.id,
        amount: 500,
    )

    expect(refund).to be_a(Stripe::Refund)
  end
end
