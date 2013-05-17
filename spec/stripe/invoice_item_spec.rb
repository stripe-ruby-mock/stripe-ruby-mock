require 'spec_helper'

describe 'Invoice Item API' do

  before { StripeMock.start }
  after  { StripeMock.stop }

  it "should create a stripe invoice item" do
    invoice_item = Stripe::InvoiceItem.create({
      amount: 1099,
      customer: 1234,
      currency: 'USD',
      description: "invoice item desc"
    }, 'abcde')

    expect(invoice_item.amount).to eq(1099)
    expect(invoice_item.description).to eq('invoice item desc')
  end

end
