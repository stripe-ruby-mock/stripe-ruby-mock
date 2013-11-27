require 'spec_helper'

shared_examples 'Invoice API' do

  context "creating a new invoice" do
    it "creates a stripe invoice" do
      invoice = Stripe::Invoice.create
      expect(invoice.id).to match(/^test_in/)
    end

    it "stores a created stripe invoice in memory" do
      invoice = Stripe::Invoice.create
      data = test_data_source(:invoices)
      expect(data[invoice.id]).to_not be_nil
      expect(data[invoice.id][:id]).to eq(invoice.id)
    end
  end

  context "retrieving an invoice" do
    it "retrieves a stripe invoice" do
      original = Stripe::Invoice.create
      invoice = Stripe::Invoice.retrieve(original.id)
      expect(invoice.id).to eq(original.id)
    end
  end

  context "retrieving a list of invoices" do
    before do
      @customer = Stripe::Customer.create(email: 'johnny@appleseed.com')
      @invoice = Stripe::Invoice.create(customer: @customer.id)
      @invoice2 = Stripe::Invoice.create
    end

    it "stores invoices for a customer in memory" do
      expect(@customer.invoices.map(&:id)).to eq([@invoice.id])
    end

    it "stores all invoices in memory" do
      expect(Stripe::Invoice.all.map(&:id)).to eq([@invoice.id, @invoice2.id])
    end

    it "defaults count to 10 invoices" do
      11.times { Stripe::Invoice.create }
      expect(Stripe::Invoice.all.count).to eq(10)
    end

    context "when passing count" do
      it "gets that many invoices" do
        expect(Stripe::Invoice.all(count: 1).count).to eq(1)
      end
    end
  end

end
