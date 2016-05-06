require 'spec_helper'

shared_examples 'Balance Transaction API' do

  it "returns an error if balance transaction does not exist" do
    txn_id = 'txn_xxxxxxxxxxxxxxxxxxxxxxxx'

    expect {
      Stripe::BalanceTransaction.retrieve(txn_id)
    }.to raise_error { |e|
      expect(e).to be_a(Stripe::InvalidRequestError)
      expect(e.message).to eq('No such balance_transaction: ' + txn_id)
    }
  end

  it "retrieves a single balance transaction" do
    txn_id = 'txn_05RsQX2eZvKYlo2C0FRTGSSA'
    txn = Stripe::BalanceTransaction.retrieve(txn_id)

    expect(txn).to be_a(Stripe::BalanceTransaction)
    expect(txn.id).to eq(txn_id)
  end

  describe "listing balance transactions" do

    it "retrieves all balance transactions" do
      disputes = Stripe::BalanceTransaction.all

      expect(disputes.count).to eq(10)
      expect(disputes.map &:id).to include('txn_05RsQX2eZvKYlo2C0FRTGSSA','txn_15RsQX2eZvKYlo2C0ERTYUIA', 'txn_25RsQX2eZvKYlo2C0ZXCVBNM', 'txn_35RsQX2eZvKYlo2C0QAZXSWE', 'txn_45RsQX2eZvKYlo2C0EDCVFRT', 'txn_55RsQX2eZvKYlo2C0OIKLJUY', 'txn_65RsQX2eZvKYlo2C0ASDFGHJ', 'txn_75RsQX2eZvKYlo2C0EDCXSWQ', 'txn_85RsQX2eZvKYlo2C0UJMCDET', 'txn_95RsQX2eZvKYlo2C0EDFRYUI')
    end

  end

end
