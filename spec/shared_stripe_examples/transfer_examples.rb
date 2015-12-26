require 'spec_helper'

shared_examples 'Transfer API' do

  it "creates a stripe transfer" do
    recipient = Stripe::Recipient.create(type:  "corporation", name: "MyCo")
    transfer = Stripe::Transfer.create(amount:  "100", currency: "usd", recipient: recipient.id)

    expect(transfer.id).to match /^test_tr/
    expect(transfer.amount).to eq('100')
    expect(transfer.currency).to eq('usd')
    expect(transfer.recipient).to eq recipient.id
    expect(transfer.reversed).to eq(false)
  end

  describe "listing transfers" do
    let(:recipient) { Stripe::Recipient.create(type: "corporation", name: "MyCo") }

    before do
      3.times do
        Stripe::Transfer.create(amount: "100", currency: "usd", recipient: recipient.id)
      end
    end

    it "without params retrieves all tripe transfers" do
      expect(Stripe::Transfer.all.count).to eq(3)
    end

    it "accepts a limit param" do
      expect(Stripe::Transfer.all(limit: 2).count).to eq(2)
    end

    it "filters the search to a specific recipient" do
      r2 = Stripe::Recipient.create(type: "corporation", name: "MyCo")
      Stripe::Transfer.create(amount: "100", currency: "usd", recipient: r2.id)

      expect(Stripe::Transfer.all(recipient: r2.id).count).to eq(1)
    end
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

  it 'when amount is not integer', live: true do
    rec = Stripe::Recipient.create({
                                       type:  'individual',
                                       name: 'Alex Smith',
                                   })
    expect { Stripe::Transfer.create(amount: '400.2',
                                       currency: 'usd',
                                       recipient: rec.id,
                                       description: 'Transfer for test@example.com') }.to raise_error { |e|
      expect(e).to be_a Stripe::InvalidRequestError
      expect(e.param).to eq('amount')
      expect(e.http_status).to eq(400)
    }
  end
end
