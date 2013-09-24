require 'spec_helper'

shared_examples 'Recipient API' do

  it "generates and reads a recipient token" do
    recipient_token = StripeMock.generate_recipient_token(
      :bank_account => {
        :country => "US",
        :routing_number => "110000000",
        :account_number => "000123456789",
    })
    name = "Fred Flinstone"
    rec = Stripe::Recipient.create({
      name: name,
      type: "individual",
      email: 'blah@domain.co',
      bank_account: recipient_token
    })
    acct = rec['active_account']
    expect(acct['last4']).to eq("6789")
    expect(rec['name']).to eq(name)
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

end

