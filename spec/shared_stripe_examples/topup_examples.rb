require 'spec_helper'
require 'pp'

shared_examples 'Topup API' do

  let(:stripe_helper) { StripeMock.create_test_helper }

  describe "new topup", focus:true do
    let(:account) { Stripe::Account.create(id: 'test_account', type: 'custom', country: "US") }
    let(:action) { Stripe::Topup.create({
                                            amount: amount,
                                            currency: currency,
                                            description: 'test Top-up',
                                        })

    }
    let(:currency) { 'usd' }
    let(:amount) { 2000 }

    context "with correct values" do
      it "creates a topup" do
        topup = action
        expect(topup.amount).to eq(amount)
        expect(topup.currency).to eq(currency)
      end
    end

    context "with negative amount" do
      let(:amount) { -2000 }
      it "raises an exception " do
        expect { action }.to raise_error {|e|
          expect(e).to be_a(Stripe::InvalidRequestError)
          expect(e.message).to eq("Amount must be a positive integer")
        }
      end
    end

    context "with uppercase currency" do
      let(:currency) { 'USD' }
      it "raises an exception " do
        expect { action }.to raise_error {|e|
          expect(e).to be_a(Stripe::InvalidRequestError)
          expect(e.message).to eq("Currency must be a three-letter ISO currency code, in lowercase")
        }
      end
    end

    context "with two-letter currency" do
      let(:currency) { 'us' }
      it "raises an exception " do
        expect { action }.to raise_error {|e|
          expect(e).to be_a(Stripe::InvalidRequestError)
          expect(e.message).to eq("Currency must be a three-letter ISO currency code, in lowercase")
        }
      end
    end
  end

end
