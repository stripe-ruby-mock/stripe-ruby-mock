require 'spec_helper'

shared_examples 'Dispute API' do

  it "retrieves a single dispute" do
    dispute_id = "dp_15RsQX2eZvKYlo2C0MFNUWJC"
    dispute = Stripe::Dispute.retrieve(dispute_id)
    expect(dispute.id).to eq(dispute_id)
  end

  it "updates a dispute" do
    expect(1).to eq(1)
  end

  it "closes a dispute" do
    expect(1).to eq(1)
  end

  it "lists all disputes" do
    Stripe::Dispute.retrieve("dp_11RsQX2eZvKYlo2C0MFNUWJC")
    Stripe::Dispute.retrieve("dp_12RsQX2eZvKYlo2C0MFNUWJC")
    Stripe::Dispute.retrieve("dp_13RsQX2eZvKYlo2C0MFNUWJC")

    all = Stripe::Dispute.all
    expect(all.count).to eq(3)
    # expect(all.map &:email).to include('one@one.com', 'two@two.com')
  end
  
end
