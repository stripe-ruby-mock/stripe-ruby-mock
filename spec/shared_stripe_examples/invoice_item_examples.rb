require 'spec_helper'

shared_examples 'Invoice Item API' do

  it "creates a stripe invoice item" do
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
