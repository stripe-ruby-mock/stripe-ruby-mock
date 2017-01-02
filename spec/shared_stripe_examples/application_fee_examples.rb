require 'spec_helper'

shared_examples 'Application Fee API' do

  it "returns an error if application fee does not exist" do
    af_id = 'fee_xxxxxxxxxxxxxxxxxxxxxxxx'

    expect {
      Stripe::ApplicationFee.retrieve(af_id)
    }.to raise_error { |e|
           expect(e).to be_a(Stripe::InvalidRequestError)
           expect(e.message).to eq('No such application_fee: ' + af_id)
         }
  end

  it "retrieves a single application_fee" do
    af_id = 'fee_05RsQX2eZvKYlo2C0FRTGSSA'
    application_fee = Stripe::ApplicationFee.retrieve(af_id)

    expect(application_fee).to be_a(Stripe::ApplicationFee)
    expect(application_fee.id).to eq(af_id)
  end

  describe "listing application fees" do

    it "retrieves all application fees" do
      application_fees = Stripe::ApplicationFee.all

      expect(application_fees.count).to eq(10)
      expect(application_fees.map &:id).to include('fee_05RsQX2eZvKYlo2C0FRTGSSA','fee_15RsQX2eZvKYlo2C0ERTYUIA', 'fee_25RsQX2eZvKYlo2C0ZXCVBNM', 'fee_35RsQX2eZvKYlo2C0QAZXSWE', 'fee_45RsQX2eZvKYlo2C0EDCVFRT', 'fee_55RsQX2eZvKYlo2C0OIKLJUY', 'fee_65RsQX2eZvKYlo2C0ASDFGHJ', 'fee_75RsQX2eZvKYlo2C0EDCXSWQ', 'fee_85RsQX2eZvKYlo2C0UJMCDET', 'fee_95RsQX2eZvKYlo2C0EDFRYUI')
    end

  end


end
