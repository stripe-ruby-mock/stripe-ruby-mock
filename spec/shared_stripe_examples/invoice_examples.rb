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

  context "paying an invoice" do
    before do
      @invoice = Stripe::Invoice.create
      @invoice.pay
    end

    it 'updates attempted and paid flags' do
      expect(@invoice.attempted).to be_true
      expect(@invoice.paid).to be_true
    end

    it 'sets the charge attribute' do
      expect(@invoice.charge).to be_a String
      expect(@invoice.charge.length).to be > 0
    end
  end

  context "retrieving upcoming invoice" do
    before do
      @customer = Stripe::Customer.create(email: 'johnny@appleseed.com', card: 'some_card_token')
    end

    it 'fails without parameters' do
      expect { Stripe::Invoice.upcoming() }.to raise_error {|e|
        expect(e).to be_a(ArgumentError) }
    end

    it 'fails without a valid customer in strict mode' do
      expect { Stripe::Invoice.upcoming(customer: 'whatever') }.to raise_error {|e|
        expect(e).to be_a(Stripe::InvalidRequestError)
        expect(e.message).to eq('No such customer: whatever') }
    end

    it 'fails without a customer parameter' do
      expect { Stripe::Invoice.upcoming(gazebo: 'raindance') }.to raise_error {|e|
        expect(e).to be_a(Stripe::InvalidRequestError)
        expect(e.http_status).to eq(400)
        expect(e.message).to eq('Missing required param: customer') }
    end

    it 'fails without a subscription' do
      expect { Stripe::Invoice.upcoming(customer: @customer.id) }.to raise_error {|e|
        expect(e).to be_a(Stripe::InvalidRequestError)
        expect(e.http_status).to eq(404)
        expect(e.message).to eq("No upcoming invoices for customer: #{@customer.id}") }
    end

    it 'works when customer has a subscription' do
      @plan = Stripe::Plan.create()
      @subscription = @customer.subscriptions.create(plan: @plan.id)
      @upcoming = Stripe::Invoice.upcoming(customer: @customer.id)

      expect(@upcoming).to be_a Stripe::Invoice
      expect(@upcoming.total).to eq(@upcoming.lines.data[0].amount)
      expect(@upcoming.period_start + 2592000).to eq(@upcoming.period_end) # 2592000 = 30 days
      expect(@upcoming.period_end).to eq(@upcoming.lines.data[0].period.start)
      expect(@upcoming.period_end + 2592000).to eq(@upcoming.lines.data[0].period.end) # 2592000 = 30 days
      expect(@upcoming.next_payment_attempt).to eq(@upcoming.period_end + 3600) # 3600 = 1 hour
      expect(@upcoming.subscription).to eq(@subscription.id)
    end

    it 'calculates the right offset period' do
      @oddplan = Stripe::Plan.create(interval: "week", interval_count: 11)
      @subscription = @customer.subscriptions.create(plan: @oddplan.id)
      @upcoming = Stripe::Invoice.upcoming(customer: @customer.id)

      expect(@upcoming.period_end).to eq(@upcoming.lines.data[0].period.start)
      expect(@upcoming.period_start + 6652800).to eq(@upcoming.period_end) # 6652800 = 11 weeks
      expect(@upcoming.period_end).to eq(@upcoming.lines.data[0].period.start)
      expect(@upcoming.period_end + 6652800).to eq(@upcoming.lines.data[0].period.end) # 6652800 = 11 weeks
      expect(@upcoming.next_payment_attempt).to eq(@upcoming.period_end + 3600) # 3600 = 1 hour
    end

    it 'chooses the most recent of multiple subscriptions' do
      @shortplan = Stripe::Plan.create(interval: "week") # 1 week sub
      @plainplan = Stripe::Plan.create()                 # 1 month sub
      @longplan  = Stripe::Plan.create(interval: "year") # 1 year sub

      @plainsub = @customer.subscriptions.create(plan: @plainplan.id)
      @shortsub = @customer.subscriptions.create(plan: @shortplan.id)
      @longsub  = @customer.subscriptions.create(plan: @longplan.id)

      @upcoming = Stripe::Invoice.upcoming(customer: @customer.id)

      expect(@upcoming.period_start + 604800).to eq(@upcoming.period_end) # 604800 = 1 week
      expect(@upcoming.period_end + 604800).to eq(@upcoming.lines.data[0].period.end) # 604800 = 1 week
      expect(@upcoming.subscription).to eq(@shortsub.id)
    end

  end
end
