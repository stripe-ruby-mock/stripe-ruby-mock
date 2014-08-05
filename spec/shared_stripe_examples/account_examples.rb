require 'spec_helper'

shared_examples 'Account API' do
  it "retrieves a stripe account" do
    account = Stripe::Account.retrieve
    expect(account).to respond_to(:display_name)
  end

  context "With strict mode toggled off" do

    before { StripeMock.toggle_strict(false) }

    it "retrieves a stripe customer with an id that doesn't exist" do
      account = Stripe::Account.retrieve('test_account_x')
      expect(account.id).to eq('test_account_x')
      expect(account.display_name).to_not be_nil
    end
  end
end