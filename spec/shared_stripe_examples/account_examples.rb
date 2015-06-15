require 'spec_helper'

shared_examples 'Account API' do
  it 'retrieves a stripe account', live: true do
    account = Stripe::Account.retrieve

    expect(account).to be_a Stripe::Account
    expect(account.id).to match /acct\_/
  end

  it 'all', live: true do
    accounts = Stripe::Account.all

    expect(accounts).to be_a Stripe::ListObject
    expect(accounts.data).to eq []
  end
end
