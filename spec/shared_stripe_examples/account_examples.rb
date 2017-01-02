require 'spec_helper'

shared_examples 'Account API' do
  describe 'retrive accounts' do
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
    it 'retrieves all' do
      accounts = Stripe::Account.all

      expect(accounts).to be_a Stripe::ListObject
      expect(accounts.data.count).to satisfy { |n| n >= 1 }
    end
  end
  describe 'create account' do
    it 'creates one more account' do
      account = Stripe::Account.create(email: 'lol@what.com')

      expect(account).to be_a Stripe::Account
    end
    it 'create managed account' do
      account = Stripe::Account.create(managed: true, country: 'CA')

      # expect(account).to include(:keys)
      expect(account.keys).not_to be_nil
      expect(account.keys.secret).to match /sk_(live|test)_[\d\w]+/
      expect(account.keys.publishable).to match /pk_(live|test)_[\d\w]+/
      expect(account.external_accounts).not_to be_nil
      expect(account.external_accounts.data).to be_an Array
      expect(account.external_accounts.url).to match /\/v1\/accounts\/.*\/external_accounts/
    end
  end
  describe 'updates account' do
    it 'updates account' do
      account = Stripe::Account.retrieve
      account.support_phone = '1234567'
      account.save

      account = Stripe::Account.retrieve

      expect(account.support_phone).to eq '1234567'
    end
  end

  it 'deauthorizes the stripe account', live: false do
    account = Stripe::Account.retrieve
    result = account.deauthorize('CLIENT_ID')

    expect(result).to be_a Stripe::StripeObject
    expect(result[:stripe_user_id]).to eq account[:id]
  end
end
