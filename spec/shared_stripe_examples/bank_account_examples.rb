require 'spec_helper'

shared_examples 'Bank Account API' do

  it 'creates/returns a bank_account when using customer.bank_accounts.create given a bank_account token' do
    customer = Stripe::Customer.create(id: 'test_customer_sub')
    bank_account_token = stripe_helper.generate_bank_token(last4: "1123", bank_name: "BANK OF AMERICA", country: "US")
    bank_account = customer.bank_accounts.create(bank_account: bank_account_token)

    expect(bank_account.customer).to eq('test_customer_sub')
    expect(bank_account.last4).to eq("1123")
    expect(bank_account.bank_name).to eq("BANK OF AMERICA")
    expect(bank_account.country).to eq("US")

    customer = Stripe::Customer.retrieve('test_customer_sub')
    expect(customer.bank_accounts.count).to eq(1)
    bank_account = customer.bank_accounts.data.first
    expect(bank_account.customer).to eq('test_customer_sub')
    expect(bank_account.last4).to eq("1123")
    expect(bank_account.bank_name).to eq("BANK OF AMERICA")
    expect(bank_account.country).to eq("US")
  end

  it 'creates/returns a bank_account when using customer.bank_accounts.create given bank_account params' do
    customer = Stripe::Customer.create(id: 'test_customer_sub')
    bank_account = customer.bank_accounts.create(bank_account: {
      account_number: '00987654321',
      routing_number: '22211122211',
      bank_name: "BANK OF AMERICA",
      country: 'US',
      cvc: '123'
    })

    expect(bank_account.customer).to eq('test_customer_sub')
    expect(bank_account.last4).to eq("4321")
    expect(bank_account.bank_name).to eq("BANK OF AMERICA")
    expect(bank_account.country).to eq("US")

    customer = Stripe::Customer.retrieve('test_customer_sub')
    expect(customer.bank_accounts.count).to eq(1)
    bank_account = customer.bank_accounts.data.first
    expect(bank_account.customer).to eq('test_customer_sub')
    expect(bank_account.last4).to eq("4321")
    expect(bank_account.bank_name).to eq("BANK OF AMERICA")
    expect(bank_account.country).to eq("US")
  end


  it "creates a single bank_account with a generated bank_account token", :live => true do
    customer = Stripe::Customer.create
    expect(customer.bank_accounts.count).to eq 0

    customer.bank_accounts.create :bank_account => stripe_helper.generate_bank_token
    # Yes, stripe-ruby does not actually add the new bank_account to the customer instance
    expect(customer.bank_accounts.count).to eq 0

    customer2 = Stripe::Customer.retrieve(customer.id)
    expect(customer2.bank_accounts.count).to eq 1
    expect(customer2.default_bank_account).to eq customer2.bank_accounts.first.id
  end

  it 'create does not change the customers default bank_account if already set' do
    customer = Stripe::Customer.create(id: 'test_customer_sub', default_bank_account: "test_cc_original")
    bank_account_token = stripe_helper.generate_bank_token(last4: "1123", bank_name: "BANK OF AMERICA", country: "US")
    bank_account = customer.bank_accounts.create(bank_account: bank_account_token)

    customer = Stripe::Customer.retrieve('test_customer_sub')
    expect(customer.default_bank_account).to eq("test_cc_original")
  end

  it 'create updates the customers default bank_account if not set' do
    customer = Stripe::Customer.create(id: 'test_customer_sub')
    bank_account_token = stripe_helper.generate_bank_token(last4: "1123", bank_name: "BANK OF AMERICA", country: "US")
    bank_account = customer.bank_accounts.create(bank_account: bank_account_token)

    customer = Stripe::Customer.retrieve('test_customer_sub')
    expect(customer.default_bank_account).to_not be_nil
  end

  context "retrieval and deletion" do
    let!(:customer) { Stripe::Customer.create(id: 'test_customer_sub') }
    let!(:bank_account_token) { stripe_helper.generate_bank_token(last4: "1123", bank_name: "BANK OF AMERICA", country: "US") }
    let!(:bank_account) { customer.bank_accounts.create(bank_account: bank_account_token) }

    it "retrieves a customers bank_account" do
      retrieved = customer.bank_accounts.retrieve(bank_account.id)
      expect(retrieved.to_s).to eq(bank_account.to_s)
    end

    it "retrieves a customer's bank_account after re-fetching the customer" do
      retrieved = Stripe::Customer.retrieve(customer.id).bank_accounts.retrieve(bank_account.id)
      expect(retrieved.id).to eq bank_account.id
    end

    it "deletes a customers bank_account" do
      pending "Bank accounts can't be deleted yet"
      bank_account.delete
      retrieved_cus = Stripe::Customer.retrieve(customer.id)
      expect(retrieved_cus.bank_accounts.data).to be_empty
    end

    it "deletes a customers bank_account then set the default_bank_account to nil" do
      pending "Bank accounts can't be deleted yet"
      bank_account.delete
      retrieved_cus = Stripe::Customer.retrieve(customer.id)
      expect(retrieved_cus.default_bank_account).to be_nil
    end

    it "updates the default bank_account if deleted" do
      pending "Bank accounts can't be deleted yet"
      bank_account.delete
      retrieved_cus = Stripe::Customer.retrieve(customer.id)
      expect(retrieved_cus.default_bank_account).to be_nil
    end

    context "deletion when the user has two bank_accounts" do
      let!(:bank_account_token_2) { stripe_helper.generate_bank_token(last4: "1123", bank_name: "BANK OF AMERICA", country: "US") }
      let!(:bank_account_2) { customer.bank_accounts.create(bank_account: bank_account_token_2) }

      it "has just one bank_account anymore" do
        pending "Bank accounts can't be deleted yet"
        bank_account.delete
        retrieved_cus = Stripe::Customer.retrieve(customer.id)
        expect(retrieved_cus.bank_accounts.data.count).to eq 1
        expect(retrieved_cus.bank_accounts.data.first.id).to eq bank_account_2.id
      end

      it "sets the default_bank_account id to the last bank_account remaining id" do
        pending "Bank accounts can't be deleted yet"
        bank_account.delete
        retrieved_cus = Stripe::Customer.retrieve(customer.id)
        expect(retrieved_cus.default_bank_account).to eq bank_account_2.id
      end
    end
  end

  describe "Errors", :live => true do
    it "throws an error when the customer does not have the retrieving bank_account id" do
      customer = Stripe::Customer.create
      bank_account_id = "bank_account_123"
      expect { customer.bank_accounts.retrieve(bank_account_id) }.to raise_error {|e|
        expect(e).to be_a Stripe::InvalidRequestError
        expect(e.message).to include "Customer", customer.id, "does not have", bank_account_id
        expect(e.param).to eq 'bank_account'
        expect(e.http_status).to eq 404
      }
    end
  end

  context "update bank_account" do
    let!(:customer) { Stripe::Customer.create(id: 'test_customer_sub') }
    let!(:bank_account_token) { stripe_helper.generate_bank_token(last4: "1123", bank_name: "BANK OF AMERICA", country: "US") }
    let!(:bank_account) { customer.bank_accounts.create(bank_account: bank_account_token) }

    it "updates the bank_account" do
      pending "Stripe doesn't allow updating bank accounts yet"
      bank_name = "BANK OF THE WEST"
      country = "NZ"

      bank_account.bank_name = bank_name
      bank_account.country = country
      bank_account.save

      retrieved = customer.bank_accounts.retrieve(bank_account.id)

      expect(retrieved.bank_name).to eq(bank_name)
      expect(retrieved.country).to eq(country)
    end
  end

  context "retrieve multiple bank_accounts" do

    it "retrieves a list of multiple bank_accounts" do
      customer = Stripe::Customer.create(id: 'test_customer_bank_account')

      bank_account_token = stripe_helper.generate_bank_token(last4: "1123", bank_name: "BANK OF AMERICA", country: "US")
      bank_account1 = customer.bank_accounts.create(bank_account: bank_account_token)
      bank_account_token = stripe_helper.generate_bank_token(last4: "1124", bank_name: "ORANGE", country: "GB")
      bank_account2 = customer.bank_accounts.create(bank_account: bank_account_token)

      customer = Stripe::Customer.retrieve('test_customer_bank_account')

      list = customer.bank_accounts.all

      expect(list.object).to eq("list")
      expect(list.count).to eq(2)
      expect(list.data.length).to eq(2)

      expect(list.data.first.object).to eq("bank_account")
      expect(list.data.first.to_hash).to eq(bank_account1.to_hash)

      expect(list.data.last.object).to eq("bank_account")
      expect(list.data.last.to_hash).to eq(bank_account2.to_hash)
    end

    it "retrieves an empty list if there's no subscriptions" do
      Stripe::Customer.create(id: 'no_bank_accounts')
      customer = Stripe::Customer.retrieve('no_bank_accounts')

      list = customer.bank_accounts.all

      expect(list.object).to eq("list")
      expect(list.count).to eq(0)
      expect(list.data.length).to eq(0)
    end
  end

end
