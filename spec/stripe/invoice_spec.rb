require 'spec_helper'

describe 'Invoice API' do

  before { StripeMock.start }
  after  { StripeMock.stop }

  it "should create a stripe invoice item" do
    invoice = Stripe::InvoiceItem.create({
      amount: 1099,
      customer: 1234,
      currency: 'USD',
      description: "invoice desc"
    }, 'abcde')

    expect(invoice.amount).to eq(1099)
    expect(invoice.description).to eq('invoice desc')
  end

end
