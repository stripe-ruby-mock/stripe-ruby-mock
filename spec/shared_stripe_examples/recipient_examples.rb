require 'spec_helper'

shared_examples 'Recipient API' do

  it "creates a stripe recipient with a default card" do
    recipient = Stripe::Recipient.create({
      type:  "corporation",
      name: "MyCo",
      email: "owner@myco.com",
      bank_account: 'void_bank_token'
    })
    expect(recipient.id).to match /^test_rp/
    expect(recipient.name).to eq('MyCo')
    expect(recipient.email).to eq('owner@myco.com')

    expect(recipient.active_account).to_not be_nil
    expect(recipient.active_account.bank_name).to_not be_nil
    expect(recipient.active_account.last4).to_not be_nil
  end

  it "stores a created stripe recipient in memory" do
    recipient = Stripe::Recipient.create({
      type:  "individual",
      name: "Customer One",
      bank_account: 'bank_account_token_1'
    })
    recipient2 = Stripe::Recipient.create({
      type:  "individual",
      name: "Customer Two",
      bank_account: 'bank_account_token_1'
    })
    data = test_data_source(:recipients)
    expect(data[recipient.id]).to_not be_nil
    expect(data[recipient.id][:name]).to eq("Customer One")

    expect(data[recipient2.id]).to_not be_nil
    expect(data[recipient2.id][:name]).to eq("Customer Two")
  end

  it "retrieves a stripe recipient" do
    original = Stripe::Recipient.create({
      type:  "individual",
      name: "Bob",
      email: "bob@example.com"
    })
    recipient = Stripe::Recipient.retrieve(original.id)

    expect(recipient.id).to eq(original.id)
    expect(recipient.name).to eq(original.name)
    expect(recipient.email).to eq(original.email)
  end

  it "cannot retrieve a recipient that doesn't exist" do
    expect { Stripe::Recipient.retrieve('nope') }.to raise_error {|e|
      expect(e).to be_a Stripe::InvalidRequestError
      expect(e.param).to eq('recipient')
      expect(e.http_status).to eq(404)
    }
  end

end

