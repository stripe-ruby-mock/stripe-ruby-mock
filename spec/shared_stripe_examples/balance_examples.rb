require 'spec_helper'

shared_examples 'Balance API' do

  it "retrieves a stripe balance" do
    StripeMock.set_account_balance(2000)
    balance = Stripe::Balance.retrieve()
    expect(balance.available[0].amount).to eq(2000)
  end

end
