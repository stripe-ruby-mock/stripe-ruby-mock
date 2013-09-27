require 'spec_helper'

shared_examples 'Bank Account Token Mocking' do

  it "generates and reads a bank account token" do
    bank_token = StripeMock.generate_bank_token({
      :bank_account => {
        :country => "US",
        :routing_number => "110000000",
        :account_number => "000123456789",
      }
    })
    name = "Fred Flinstone"
    recipient = Stripe::Recipient.create({
      name: name,
      type: "individual",
      email: 'blah@domain.co',
      bank_account: bank_token
    })
    account = recipient['active_account']
    expect(account['last4']).to eq("6789")
    expect(recipient['name']).to eq(name)
  end

end

