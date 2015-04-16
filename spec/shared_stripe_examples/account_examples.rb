require 'spec_helper'

shared_examples 'Account API' do
  it 'retrieves a stripe account', live: true do
    account = Stripe::Account.retrieve

    expect(account).to be_a Stripe::Account
    expect(account.id).to match /acct\_/
  end
  it 'retrieves a specific stripe account' do
    account = Stripe::Account.retrieve('acct_103ED82ePvKYlo2C')

    expect(account).to be_a Stripe::Account
    expect(account.id).to match /acct\_/
  end
  it 'retrieves all', live: true do
    accounts = Stripe::Account.all

    expect(accounts).to be_a Stripe::ListObject
    expect(accounts.data.count).to satisfy { |n| n >= 1 }
  end
  it 'creates one more account' do
    account = Stripe::Account.create(email: 'lol@what.com')

    expect(account).to be_a Stripe::Account
  end
  it 'updates account' do
    account = Stripe::Account.retrieve
    account.support_phone = '1234567'
    account.save

    account = Stripe::Account.retrieve

    expect(account.support_phone).to eq '1234567'
  end
end
