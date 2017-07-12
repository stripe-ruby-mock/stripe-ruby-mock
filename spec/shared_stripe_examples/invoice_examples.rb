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

    it "is marked as having more when more objects exist" do
      11.times { Stripe::Invoice.create }

      expect(Stripe::Invoice.all.has_more).to eq(true)
    end

    context "when passing limit" do
      it "gets that many invoices" do
        expect(Stripe::Invoice.all(limit: 1).count).to eq(1)
      end
    end
  end

  context "paying an invoice" do
    before do
      @invoice = Stripe::Invoice.create
    end

    it 'updates attempted and paid flags' do
      @invoice.pay
      expect(@invoice.attempted).to eq(true)
      expect(@invoice.paid).to eq(true)
    end

    it 'creates a new charge object' do
      expect{ @invoice.pay }.to change { Stripe::Charge.list.data.count }.by 1
    end

    it 'sets the charge attribute' do
      @invoice.pay
      expect(@invoice.charge).to be_a String
      expect(@invoice.charge.length).to be > 0
    end

    it 'charges the invoice customers default card' do
      customer = Stripe::Customer.create({
        source: stripe_helper.generate_card_token
      })
      customer_invoice = Stripe::Invoice.create({customer: customer})

      customer_invoice.pay

      expect(Stripe::Charge.list.data.first.customer).to eq customer.id
    end
  end

  context "retrieving upcoming invoice" do
    before do
      @customer = Stripe::Customer.create(email: 'johnny@appleseed.com', source: stripe_helper.generate_card_token)
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

    describe 'parameters validation' do
      let!(:customer) { Stripe::Customer.create(source: stripe_helper.generate_card_token) }
      it 'fails without a subscription or subscription plan if subscription proration date is specified', live: true do
        expect { Stripe::Invoice.upcoming(customer: customer.id, subscription_proration_date: Time.now.to_i) }.to raise_error do |e|
          expect(e).to be_a Stripe::InvalidRequestError
          expect(e.http_status).to eq 400
          expect(e.message).to eq 'When previewing changes to a subscription, you must specify either `subscription` or `subscription_plan`'
        end
      end
      context 'with a plan' do
        let!(:plan) { Stripe::Plan.create(id: '50m', amount: 5000, interval: 'month', name: '50m', currency: 'usd') }
        it 'fails without a subscription if proration date is specified', live: true do
          expect { Stripe::Invoice.upcoming(customer: customer.id, subscription_plan: plan.id, subscription_proration_date: Time.now.to_i) }.to raise_error do |e|
            expect(e).to be_a Stripe::InvalidRequestError
            expect(e.http_status).to eq 400
            expect(e.message).to eq 'Cannot specify proration date without specifying a subscription'
          end
        end
        after { plan.delete }
      end
      after { customer.delete }
    end

    describe 'with a customer and a plan' do
      let!(:customer) { Stripe::Customer.create(source: stripe_helper.generate_card_token) }
      let!(:plan) { Stripe::Plan.create(id: '50m', amount: 5000, interval: 'month', name: '50m', currency: 'usd') }

      it 'works when customer has a subscription', :live => true do
        # Given
        quantity = 3
        subscription = Stripe::Subscription.create(plan: plan.id, customer: customer.id, quantity: quantity)

        # When
        upcoming = Stripe::Invoice.upcoming(customer: customer.id)

        # Then
        expect(upcoming).to be_a Stripe::Invoice
        expect(upcoming.customer).to eq(customer.id)
        expect(upcoming.amount_due).to eq plan.amount * quantity
        expect(upcoming.total).to eq(upcoming.lines.data[0].amount)
        expect(upcoming.period_end).to eq(upcoming.lines.data[0].period.start)
        expect(Time.at(upcoming.period_start).to_datetime >> 1).to eq(Time.at(upcoming.period_end).to_datetime) # +1 month
        expect(Time.at(upcoming.period_start).to_datetime >> 2).to eq(Time.at(upcoming.lines.data[0].period.end).to_datetime) # +1 month
        expect(upcoming.next_payment_attempt).to eq(upcoming.period_end + 3600) # +1 hour
        expect(upcoming.subscription).to eq(subscription.id)
      end

      [false, true].each do |with_trial|
        describe "prorating a subscription with a new plan, with_trial: #{with_trial}" do
          let!(:new_plan) { Stripe::Plan.create(id: '100y', amount: 10000, interval: 'year', name: '100y', currency: 'usd') }
          it 'prorates', live: true do
            # Given
            initial_quantity = 3
            subscription = Stripe::Subscription.create(plan: plan.id, customer: customer.id, quantity: initial_quantity)
            proration_date = Time.now + 5 * 24 * 3600 # 5 days later
            new_quantity = 2
            unused_amount = plan.amount * initial_quantity * (subscription.current_period_end - proration_date.to_i) / (subscription.current_period_end - subscription.current_period_start)
            prorated_amount_due = new_plan.amount * new_quantity - unused_amount
            credit_balance = 1000
            customer.account_balance = -credit_balance
            customer.save
            query = { customer: customer.id, subscription: subscription.id, subscription_plan: new_plan.id, subscription_proration_date: proration_date.to_i, subscription_quantity: new_quantity }
            query[:subscription_trial_end] = (DateTime.now >> 1).to_time.to_i if with_trial

            # When
            upcoming = Stripe::Invoice.upcoming(query)

            # Then
            expect(upcoming).to be_a Stripe::Invoice
            expect(upcoming.customer).to eq(customer.id)
            if with_trial
              expect(upcoming.amount_due).to eq 0
            else
              expect(upcoming.amount_due).to be_within(1).of prorated_amount_due - credit_balance
            end
            expect(upcoming.starting_balance).to eq -credit_balance
            expect(upcoming.ending_balance).to be_nil
            expect(upcoming.subscription).to eq(subscription.id)
            expect(upcoming.lines.data[0].proration).to be_truthy
            expect(upcoming.lines.data[0].plan.id).to eq '50m'
            expect(upcoming.lines.data[0].amount).to be_within(1).of -unused_amount
            expect(upcoming.lines.data[0].quantity).to eq initial_quantity
            expect(upcoming.lines.data[1].proration).to be_falsey
            expect(upcoming.lines.data[1].plan.id).to eq '100y'
            expect(upcoming.lines.data[1].amount).to eq with_trial ? 0 : 20000
            expect(upcoming.lines.data[1].quantity).to eq new_quantity
          end
          after { new_plan.delete }
        end
      end

      after { plan.delete }
      after { customer.delete }
    end

    it 'sets the start and end of billing periods correctly when plan has an interval_count' do
      @oddplan = stripe_helper.create_plan(interval: "week", interval_count: 11)
      @subscription = Stripe::Subscription.create(plan: @oddplan.id, customer: @customer.id)
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

      @plainsub = Stripe::Subscription.create(plan: @plainplan.id, customer: @customer.id)
      @shortsub = Stripe::Subscription.create(plan: @shortplan.id, customer: @customer.id)
      @longsub  = Stripe::Subscription.create(plan: @longplan.id, customer: @customer.id)

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
        subscription = Stripe::Subscription.create(plan: plan.id, customer: @customer.id)
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
        @sub = Stripe::Subscription.create(plan: @plan.id, customer: @customer.id, current_period_start: Time.utc(2014,1,1,12).to_i)
        @upcoming = Stripe::Invoice.upcoming(customer: @customer.id)

        expect(Time.at(@upcoming.period_start)).to               eq(Time.utc(2014,1,1,12))
        expect(Time.at(@upcoming.period_end)).to                 eq(Time.utc(2014,2,1,12))
        expect(Time.at(@upcoming.lines.data[0].period.start)).to eq(Time.utc(2014,2,1,12))
        expect(Time.at(@upcoming.lines.data[0].period.end)).to   eq(Time.utc(2014,3,1,12))
      end

      it 'for one year plan on the 1st' do
        @plan = stripe_helper.create_plan(interval: "year")
        @sub = Stripe::Subscription.create(plan: @plan.id, customer: @customer.id, current_period_start: Time.utc(2012,1,1,12).to_i)
        @upcoming = Stripe::Invoice.upcoming(customer: @customer.id)

        expect(Time.at(@upcoming.period_start)).to               eq(Time.utc(2012,1,1,12))
        expect(Time.at(@upcoming.period_end)).to                 eq(Time.utc(2013,1,1,12))
        expect(Time.at(@upcoming.lines.data[0].period.start)).to eq(Time.utc(2013,1,1,12))
        expect(Time.at(@upcoming.lines.data[0].period.end)).to   eq(Time.utc(2014,1,1,12))
      end

      it 'for one month plan on the 31st' do
        @plan = stripe_helper.create_plan()
        @sub = Stripe::Subscription.create(plan: @plan.id, customer: @customer.id, current_period_start: Time.utc(2014,1,31,12).to_i)
        @upcoming = Stripe::Invoice.upcoming(customer: @customer.id)

        expect(Time.at(@upcoming.period_start)).to               eq(Time.utc(2014,1,31,12))
        expect(Time.at(@upcoming.period_end)).to                 eq(Time.utc(2014,2,28,12))
        expect(Time.at(@upcoming.lines.data[0].period.start)).to eq(Time.utc(2014,2,28,12))
        expect(Time.at(@upcoming.lines.data[0].period.end)).to   eq(Time.utc(2014,3,31,12))
      end

      it 'for one year plan on feb. 29th' do
        @plan = stripe_helper.create_plan(interval: "year")
        @sub = Stripe::Subscription.create(plan: @plan.id, customer: @customer.id, current_period_start: Time.utc(2012,2,29,12).to_i)
        @upcoming = Stripe::Invoice.upcoming(customer: @customer.id)

        expect(Time.at(@upcoming.period_start)).to               eq(Time.utc(2012,2,29,12))
        expect(Time.at(@upcoming.period_end)).to                 eq(Time.utc(2013,2,28,12))
        expect(Time.at(@upcoming.lines.data[0].period.start)).to eq(Time.utc(2013,2,28,12))
        expect(Time.at(@upcoming.lines.data[0].period.end)).to   eq(Time.utc(2014,2,28,12))
      end

      it 'for two month plan on dec. 31st' do
        @plan = stripe_helper.create_plan(interval_count: 2)
        @sub = Stripe::Subscription.create(plan: @plan.id, customer: @customer.id, current_period_start: Time.utc(2013,12,31,12).to_i)
        @upcoming = Stripe::Invoice.upcoming(customer: @customer.id)

        expect(Time.at(@upcoming.period_start)).to               eq(Time.utc(2013,12,31,12))
        expect(Time.at(@upcoming.period_end)).to                 eq(Time.utc(2014, 2,28,12))
        expect(Time.at(@upcoming.lines.data[0].period.start)).to eq(Time.utc(2014, 2,28,12))
        expect(Time.at(@upcoming.lines.data[0].period.end)).to   eq(Time.utc(2014, 4,30,12))
      end

      it 'for three month plan on nov. 30th' do
        @plan = stripe_helper.create_plan(interval_count: 3)
        @sub = Stripe::Subscription.create(plan: @plan.id, customer: @customer.id, current_period_start: Time.utc(2013,11,30,12).to_i)
        @upcoming = Stripe::Invoice.upcoming(customer: @customer.id)

        expect(Time.at(@upcoming.period_start)).to               eq(Time.utc(2013,11,30,12))
        expect(Time.at(@upcoming.period_end)).to                 eq(Time.utc(2014, 2,28,12))
        expect(Time.at(@upcoming.lines.data[0].period.start)).to eq(Time.utc(2014, 2,28,12))
        expect(Time.at(@upcoming.lines.data[0].period.end)).to   eq(Time.utc(2014, 5,30,12))
      end
    end

  end
end
