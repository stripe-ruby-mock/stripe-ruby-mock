require 'spec_helper'

shared_examples 'Account API' do
  it "retrieves a stripe account" do
    account = Stripe::Account.retrieve
    account.should respond_to(:display_name)
  end
end