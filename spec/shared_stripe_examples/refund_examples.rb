require 'spec_helper'

shared_examples 'Refund API' do

  context 'with old API (pre 2014-06-17)' do
    before do
      StripeMock.version = StripeMock::FIRST_VERSION_DATE
    end
    it "refunds a stripe charge item" do
      charge = Stripe::Charge.create(
        amount: 999,
        currency: 'USD',
        card: 'card_token_abcde',
        description: 'card charge'
      )

      charge = charge.refund(amount: 999)

      expect(charge.refunded).to eq(true)
      expect(charge.refunds.first.amount).to eq(999)
      expect(charge.amount_refunded).to eq(999)
    end

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

  context 'with new API (post 2014-06-17)' do
    before do
      StripeMock.version = '2014-06-17'
      StripeMock.client.set_version '2014-06-17' if StripeMock.client
    end
    after do
      StripeMock.version = StripeMock::FIRST_VERSION_DATE
      StripeMock.client.set_version StripeMock::FIRST_VERSION_DATE if StripeMock.client
    end
    it "refunds a stripe charge item" do
      charge = Stripe::Charge.create(
        amount: 999,
        currency: 'USD',
        card: 'card_token_abcde',
        description: 'card charge'
      )

      refund = charge.refunds.create(amount: 999)

      expect(refund.id).to match(/test_re/)
      expect(refund.amount).to eq(999)
    end

    it "creates a stripe refund with the charge ID" do
      charge = Stripe::Charge.create(
        amount: 999,
        currency: 'USD',
        card: 'card_token_abcde',
        description: 'card charge'
      )
      refund = charge.refunds.create

      expect(charge.id).to match(/^test_ch/)
      expect(refund.charge).to eq(charge.id)
    end

    it "creates a stripe refund with a different balance transaction than the charge" do
      charge = Stripe::Charge.create(
        amount: 999,
        currency: 'USD',
        card: 'card_token_abcde',
        description: 'card charge'
      )
      refund = charge.refunds.create

      expect(charge.balance_transaction).not_to eq(refund.balance_transaction)
    end
  end

end
