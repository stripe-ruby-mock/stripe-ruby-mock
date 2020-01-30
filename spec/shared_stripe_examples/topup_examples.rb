require 'spec_helper'
require 'pp'

shared_examples 'Topup API' do

  let(:stripe_helper) { StripeMock.create_test_helper }

  describe "new topup" do
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

  describe "retrieve topup details" do
    before do
      Stripe::Topup.create(id: "tu_05RsQX2eZvKYlo2C0FRTGSSA", amount: rand(100..100000), destination_balance: "issuing", currency: 'usd')
      Stripe::Topup.create(id: "tu_15RsQX2eZvKYlo2C0ERTYUIA", amount: rand(100..100000), destination_balance: "issuing", currency: 'usd')
      Stripe::Topup.create(id: "tu_25RsQX2eZvKYlo2C0ZXCVBNM", amount: rand(100..100000), destination_balance: "issuing", currency: 'usd')
      Stripe::Topup.create(id: "tu_35RsQX2eZvKYlo2C0QAZXSWE", amount: rand(100..100000), destination_balance: "issuing", currency: 'usd')
    end
    it "retrieves all topups" do
      topups = Stripe::Topup.list

      expect(topups.count).to eq(4)
      expect(topups.map &:id).to include('tu_05RsQX2eZvKYlo2C0FRTGSSA','tu_15RsQX2eZvKYlo2C0ERTYUIA', 'tu_25RsQX2eZvKYlo2C0ZXCVBNM', 'tu_35RsQX2eZvKYlo2C0QAZXSWE')
    end
    it "retrieves topups with a limit(3)" do
      topups = Stripe::Topup.list(limit: 3)

      expected = ['tu_15RsQX2eZvKYlo2C0ERTYUIA','tu_25RsQX2eZvKYlo2C0ZXCVBNM', 'tu_35RsQX2eZvKYlo2C0QAZXSWE']
      expect(topups.map &:id).to include(*expected)
      expect(topups.count).to eq(3)
    end
    it "retrieves a single topup" do
      topup_id = 'tu_05RsQX2eZvKYlo2C0FRTGSSA'
      topup = Stripe::Topup.retrieve(topup_id)

      expect(topup).to be_a(Stripe::Topup)
      expect(topup.id).to eq(topup_id)
    end
  end

  end
