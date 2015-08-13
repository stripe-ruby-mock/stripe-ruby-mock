require 'spec_helper'

shared_examples 'Account API' do
  it "retrieves a newly created stripe account" do
    original = Stripe::Account.create({
      email: 'johnny@appleseed.com'
    })
    account = Stripe::Account.retrieve(original.id)

    expect(account.id).to eq(original.id)
    expect(account.email).to eq(original.email)
  end

  it 'all', live: true do
    accounts = Stripe::Account.all

    expect(accounts).to be_a Stripe::ListObject
    expect(accounts.data).to eq []
  end
end
