require 'spec_helper'

shared_examples 'Recipient API' do

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

end

