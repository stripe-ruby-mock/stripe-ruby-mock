require 'spec_helper'

shared_examples 'Transfer API' do

  it "creates a stripe transfer" do
    recipient = Stripe::Recipient.create(type:  "corporation", name: "MyCo")
    transfer = Stripe::Transfer.create(amount:  "100", currency: "usd", recipient: recipient.id)

    expect(transfer.id).to match /^test_tr/
    expect(transfer.amount).to eq('100')
    expect(transfer.currency).to eq('usd')
    expect(transfer.recipient).to eq recipient.id
  end


  it "retrieves a stripe transfer" do
    original = Stripe::Transfer.create(amount:  "100", currency: "usd")
    transfer = Stripe::Transfer.retrieve(original.id)

    expect(transfer.id).to eq(original.id)
    expect(transfer.amount).to eq(original.amount)
    expect(transfer.currency).to eq(original.currency)
    expect(transfer.recipient).to eq(original.recipient)
  end

  it "canceles a stripe transfer " do
    original = Stripe::Transfer.create(amount:  "100", currency: "usd")
    res, api_key = Stripe.request(:post, "/v1/transfers/#{original.id}/cancel", 'api_key', {})

    expect(res[:status]).to eq("canceled")
  end

  it "cannot retrieve a transfer that doesn't exist" do
    expect { Stripe::Transfer.retrieve('nope') }.to raise_error {|e|
      expect(e).to be_a Stripe::InvalidRequestError
      expect(e.param).to eq('transfer')
      expect(e.http_status).to eq(404)
    }
  end

end