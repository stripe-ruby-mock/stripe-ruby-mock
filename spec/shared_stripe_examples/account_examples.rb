require 'spec_helper'

shared_examples 'Account API' do
  it 'retrieves a stripe account', live: true do
    account = Stripe::Account.retrieve

    expect(account).to be_a Stripe::Account
    expect(account.id).to match /acct\_/
  end
  # it "retrieves a stripe customer with an id that doesn't exist", live: true do
  #   expect { Stripe::Account.retrieve('nope') }.to raise_error {|e|
  #                                                     expect(e).to be_a Stripe::AuthenticationError
  #                                                     expect(e.http_status).to eq(401)
  #                                                   }
  #
  # end
end
