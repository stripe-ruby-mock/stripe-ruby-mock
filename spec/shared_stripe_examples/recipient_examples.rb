require 'spec_helper'

shared_examples 'Recipient Token Mocking' do

  it "generates and reads a recipient token" do
    recipient_token = StripeMock.generate_recipient_token(
      :bank_account => {
        :country => "US",
        :routing_number => "110000000",
        :account_number => "000123456789",
    }) 
    name = "Fred Flinstone",
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

end

