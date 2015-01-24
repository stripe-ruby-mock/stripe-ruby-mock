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

  context "updating an invoice" do
    it "updates a stripe invoice" do
      invoice = Stripe::Invoice.create(currency: "cad", statement_description: "orig-desc")
      expect(invoice.currency).to eq("cad")
      expect(invoice.statement_description).to eq("orig-desc")

      invoice.currency = "usd"
      invoice.statement_description = "new-desc"
      invoice.save

      invoice = Stripe::Invoice.retrieve(invoice.id)
      expect(invoice.currency).to eq("usd")
      expect(invoice.statement_description).to eq("new-desc")
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
        expect(Stripe::Invoice.all(limit: 1).count).to eq(1)
      end
    end
  end

  context "paying an invoice" do
    before do
      @invoice = Stripe::Invoice.create
      @invoice.pay
    end

    it 'updates attempted and paid flags' do
      expect(@invoice.attempted).to eq(true)
      expect(@invoice.paid).to eq(true)
    end

    it 'sets the charge attribute' do
      expect(@invoice.charge).to be_a String
      expect(@invoice.charge.length).to be > 0
    end
  end

  context "retrieving upcoming invoice" do
    before do
      @customer = Stripe::Customer.create(email: 'johnny@appleseed.com', card: stripe_helper.generate_card_token)
    end

    it 'fails without parameters' do
      expect { Stripe::Invoice.upcoming() }.to raise_error {|e|
        expect(e).to be_a(ArgumentError) }
    end

    it 'fails without a valid customer' do
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

    it 'works when customer has a subscription', :live => true do
      plan = stripe_helper.create_plan(:id => 'has_sub')
      subscription = @customer.subscriptions.create(plan: plan.id)
      upcoming = Stripe::Invoice.upcoming(customer: @customer.id)

      expect(upcoming).to be_a Stripe::Invoice
      expect(upcoming.customer).to eq(@customer.id)
      expect(upcoming.total).to eq(upcoming.lines.data[0].amount)
      expect(upcoming.period_end).to eq(upcoming.lines.data[0].period.start)
      expect(Time.at(upcoming.period_start).to_datetime >> 1).to eq(Time.at(upcoming.period_end).to_datetime) # +1 month
      expect(Time.at(upcoming.period_start).to_datetime >> 2).to eq(Time.at(upcoming.lines.data[0].period.end).to_datetime) # +1 month
      expect(upcoming.next_payment_attempt).to eq(upcoming.period_end + 3600) # +1 hour
      expect(upcoming.subscription).to eq(subscription.id)
    end

    it 'sets the start and end of billing periods correctly when plan has an interval_count' do
      @oddplan = stripe_helper.create_plan(interval: "week", interval_count: 11)
      @subscription = @customer.subscriptions.create(plan: @oddplan.id)
      @upcoming = Stripe::Invoice.upcoming(customer: @customer.id)

      expect(@upcoming.period_start + 6652800).to eq(@upcoming.period_end) # 6652800 = +11 weeks
      expect(@upcoming.period_end).to eq(@upcoming.lines.data[0].period.start)
      expect(@upcoming.period_end + 6652800).to eq(@upcoming.lines.data[0].period.end) # 6652800 = +11 weeks
      expect(@upcoming.next_payment_attempt).to eq(@upcoming.period_end + 3600) # +1 hour
    end

    it 'chooses the most recent of multiple subscriptions' do
      @shortplan = stripe_helper.create_plan(id: 'a', interval: "week") # 1 week sub
      @plainplan = stripe_helper.create_plan(id: 'b')                 # 1 month sub
      @longplan  = stripe_helper.create_plan(id: 'c', interval: "year") # 1 year sub

      @plainsub = @customer.subscriptions.create(plan: @plainplan.id)
      @shortsub = @customer.subscriptions.create(plan: @shortplan.id)
      @longsub  = @customer.subscriptions.create(plan: @longplan.id)

      @upcoming = Stripe::Invoice.upcoming(customer: @customer.id)

      expect(@upcoming.period_start + 604800).to eq(@upcoming.period_end) # 604800 = 1 week
      expect(@upcoming.period_end + 604800).to eq(@upcoming.lines.data[0].period.end) # 604800 = 1 week
      expect(@upcoming.subscription).to eq(@shortsub.id)
    end

    context 'retrieving invoice line items' do
      it 'returns all line items for created invoice' do
        invoice = Stripe::Invoice.create(customer: @customer.id)
        line_items = invoice.lines.all

        expect(invoice).to be_a Stripe::Invoice
        expect(line_items.count).to eq(1)
        expect(line_items.data[0].object).to eq('line_item')
        expect(line_items.data[0].description).to eq('Test invoice item')
        expect(line_items.data[0].type).to eq('invoiceitem')
      end

      it 'returns all line items for upcoming invoice' do
        plan = stripe_helper.create_plan()
        subscription = @customer.subscriptions.create(plan: plan.id)
        upcoming = Stripe::Invoice.upcoming(customer: @customer.id)
        line_items = upcoming.lines.all

        expect(upcoming).to be_a Stripe::Invoice
        expect(line_items.count).to eq(1)
        expect(line_items.data[0].object).to eq('line_item')
        expect(line_items.data[0].description).to eq('Test invoice item')
        expect(line_items.data[0].type).to eq('subscription')
      end
    end

    context 'calculates month and year offsets correctly' do

      it 'for one month plan on the 1st' do
        @plan = stripe_helper.create_plan()
        @sub = @customer.subscriptions.create(plan: @plan.id, current_period_start: Time.utc(2014,1,1,12).to_i)
        @upcoming = Stripe::Invoice.upcoming(customer: @customer.id)

        expect(Time.at(@upcoming.period_start)).to               eq(Time.utc(2014,1,1,12))
        expect(Time.at(@upcoming.period_end)).to                 eq(Time.utc(2014,2,1,12))
        expect(Time.at(@upcoming.lines.data[0].period.start)).to eq(Time.utc(2014,2,1,12))
        expect(Time.at(@upcoming.lines.data[0].period.end)).to   eq(Time.utc(2014,3,1,12))
      end

      it 'for one year plan on the 1st' do
        @plan = stripe_helper.create_plan(interval: "year")
        @sub = @customer.subscriptions.create(plan: @plan.id, current_period_start: Time.utc(2012,1,1,12).to_i)
        @upcoming = Stripe::Invoice.upcoming(customer: @customer.id)

        expect(Time.at(@upcoming.period_start)).to               eq(Time.utc(2012,1,1,12))
        expect(Time.at(@upcoming.period_end)).to                 eq(Time.utc(2013,1,1,12))
        expect(Time.at(@upcoming.lines.data[0].period.start)).to eq(Time.utc(2013,1,1,12))
        expect(Time.at(@upcoming.lines.data[0].period.end)).to   eq(Time.utc(2014,1,1,12))
      end

      it 'for one month plan on the 31st' do
        @plan = stripe_helper.create_plan()
        @sub = @customer.subscriptions.create(plan: @plan.id, current_period_start: Time.utc(2014,1,31,12).to_i)
        @upcoming = Stripe::Invoice.upcoming(customer: @customer.id)

        expect(Time.at(@upcoming.period_start)).to               eq(Time.utc(2014,1,31,12))
        expect(Time.at(@upcoming.period_end)).to                 eq(Time.utc(2014,2,28,12))
        expect(Time.at(@upcoming.lines.data[0].period.start)).to eq(Time.utc(2014,2,28,12))
        expect(Time.at(@upcoming.lines.data[0].period.end)).to   eq(Time.utc(2014,3,31,12))
      end

      it 'for one year plan on feb. 29th' do
        @plan = stripe_helper.create_plan(interval: "year")
        @sub = @customer.subscriptions.create(plan: @plan.id, current_period_start: Time.utc(2012,2,29,12).to_i)
        @upcoming = Stripe::Invoice.upcoming(customer: @customer.id)

        expect(Time.at(@upcoming.period_start)).to               eq(Time.utc(2012,2,29,12))
        expect(Time.at(@upcoming.period_end)).to                 eq(Time.utc(2013,2,28,12))
        expect(Time.at(@upcoming.lines.data[0].period.start)).to eq(Time.utc(2013,2,28,12))
        expect(Time.at(@upcoming.lines.data[0].period.end)).to   eq(Time.utc(2014,2,28,12))
      end

      it 'for two month plan on dec. 31st' do
        @plan = stripe_helper.create_plan(interval_count: 2)
        @sub = @customer.subscriptions.create(plan: @plan.id, current_period_start: Time.utc(2013,12,31,12).to_i)
        @upcoming = Stripe::Invoice.upcoming(customer: @customer.id)

        expect(Time.at(@upcoming.period_start)).to               eq(Time.utc(2013,12,31,12))
        expect(Time.at(@upcoming.period_end)).to                 eq(Time.utc(2014, 2,28,12))
        expect(Time.at(@upcoming.lines.data[0].period.start)).to eq(Time.utc(2014, 2,28,12))
        expect(Time.at(@upcoming.lines.data[0].period.end)).to   eq(Time.utc(2014, 4,30,12))
      end

      it 'for three month plan on nov. 30th' do
        @plan = stripe_helper.create_plan(interval_count: 3)
        @sub = @customer.subscriptions.create(plan: @plan.id, current_period_start: Time.utc(2013,11,30,12).to_i)
        @upcoming = Stripe::Invoice.upcoming(customer: @customer.id)

        expect(Time.at(@upcoming.period_start)).to               eq(Time.utc(2013,11,30,12))
        expect(Time.at(@upcoming.period_end)).to                 eq(Time.utc(2014, 2,28,12))
        expect(Time.at(@upcoming.lines.data[0].period.start)).to eq(Time.utc(2014, 2,28,12))
        expect(Time.at(@upcoming.lines.data[0].period.end)).to   eq(Time.utc(2014, 5,30,12))
      end
    end

  end
end
