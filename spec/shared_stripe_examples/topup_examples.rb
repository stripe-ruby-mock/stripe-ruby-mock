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

  it "retrieves a single topup" do
    topup_id = 'tu_05RsQX2eZvKYlo2C0FRTGSSA'
    topup = Stripe::Topup.retrieve(topup_id)

    expect(topup).to be_a(Stripe::Topup)
    expect(topup.id).to eq(topup_id)
  end

  describe "listing topups" do

    it "retrieves all topups" do
      topups = Stripe::Topup.list

      expect(topups.count).to eq(10)
      expect(topups.map &:id).to include('tu_05RsQX2eZvKYlo2C0FRTGSSA','tu_15RsQX2eZvKYlo2C0ERTYUIA', 'tu_25RsQX2eZvKYlo2C0ZXCVBNM', 'tu_35RsQX2eZvKYlo2C0QAZXSWE', 'tu_45RsQX2eZvKYlo2C0EDCVFRT', 'tu_55RsQX2eZvKYlo2C0OIKLJUY', 'tu_65RsQX2eZvKYlo2C0ASDFGHJ', 'tu_75RsQX2eZvKYlo2C0EDCXSWQ', 'tu_85RsQX2eZvKYlo2C0UJMCDET', 'tu_95RsQX2eZvKYlo2C0EDFRYUI')
    end

    it "retrieves topups with a limit(3)" do
      topups = Stripe::Topup.list(limit: 3)

      expect(topups.count).to eq(3)
      expected = ['tu_95RsQX2eZvKYlo2C0EDFRYUI','tu_85RsQX2eZvKYlo2C0UJMCDET', 'tu_75RsQX2eZvKYlo2C0EDCXSWQ']
      expect(topups.map &:id).to include(*expected)
    end

  end

end
