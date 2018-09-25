require 'spec_helper'

shared_examples 'Plan API' do
  let(:product_attributes){ {id: "prod_abc123", name: "My Mock Product", type: "service"} }
  let(:product) { Stripe::Product.create(product_attributes) }
  let(:plan_attributes) { {
    :id => 'prod_abc123',
    :product => product_attributes[:id],
    :name => 'My Mock Plan',
    :amount => 9900,
    :currency => 'USD',
    :interval => 1,
    :metadata => {
      :description => "desc text",
      :info => "info text"
    },
    :trial_period_days => 30
  } }
  let(:idless_attributes){ plan_attributes.merge({id: nil}) }
  let(:plan) { Stripe::Plan.create(plan_attributes) }

  #before(:each) do
  #  product
  #end

  it "creates a stripe plan" do
    expect(plan.id).to eq('prod_abc123')
    expect(plan.name).to eq('My Mock Plan')
    expect(plan.amount).to eq(9900)

    expect(plan.currency).to eq('USD')
    expect(plan.interval).to eq(1)

    expect(plan.metadata.description).to eq('desc text')
    expect(plan.metadata.info).to eq('info text')

    expect(plan.trial_period_days).to eq(30)
  end

  it "creates a stripe plan without specifying ID" do
    idless_attributes = plan_attributes.merge({id: nil})
    expect(idless_attributes[:id]).to be_nil

    plan = Stripe::Plan.create(idless_attributes)
    expect(plan.id).to match(/^test_plan_1/)
  end

  it "stores a created stripe plan in memory" do
    plan = Stripe::Plan.create(
      :id => 'pid_2',
      :product => 'prod_222',
      :name => 'The Second Plan',
      :amount => 1100,
      :currency => 'USD',
      :interval => 1
    )
    plan2 = Stripe::Plan.create(
      :id => 'pid_3',
      :product => 'prod_333',
      :name => 'The Third Plan',
      :amount => 7777,
      :currency => 'USD',
      :interval => 1
    )
    data = test_data_source(:plans)
    expect(data[plan.id]).to_not be_nil
    expect(data[plan.id][:amount]).to eq(1100)

    expect(data[plan2.id]).to_not be_nil
    expect(data[plan2.id][:amount]).to eq(7777)
  end

  it "retrieves a stripe plan" do
    original = stripe_helper.create_plan(amount: 1331)
    plan = Stripe::Plan.retrieve(original.id)

    expect(plan.id).to eq(original.id)
    expect(plan.amount).to eq(original.amount)
  end

  it "updates a stripe plan" do
    stripe_helper.create_plan(id: 'super_member', amount: 111)

    plan = Stripe::Plan.retrieve('super_member')
    expect(plan.amount).to eq(111)

    plan.amount = 789
    plan.save
    plan = Stripe::Plan.retrieve('super_member')
    expect(plan.amount).to eq(789)
  end

  it "cannot retrieve a stripe plan that doesn't exist" do
    expect { Stripe::Plan.retrieve('nope') }.to raise_error {|e|
      expect(e).to be_a Stripe::InvalidRequestError
      expect(e.param).to eq('plan')
      expect(e.http_status).to eq(404)
    }
  end

  it "deletes a stripe plan" do
    stripe_helper.create_plan(id: 'super_member', amount: 111)

    plan = Stripe::Plan.retrieve('super_member')
    expect(plan).to_not be_nil

    plan.delete

    expect { Stripe::Plan.retrieve('super_member') }.to raise_error {|e|
      expect(e).to be_a Stripe::InvalidRequestError
      expect(e.param).to eq('plan')
      expect(e.http_status).to eq(404)
    }
  end

  it "retrieves all plans" do
    stripe_helper.create_plan(id: 'Plan One', amount: 54321)
    stripe_helper.create_plan(id: 'Plan Two', amount: 98765)

    all = Stripe::Plan.all
    expect(all.count).to eq(2)
    expect(all.map &:id).to include('Plan One', 'Plan Two')
    expect(all.map &:amount).to include(54321, 98765)
  end

  it 'retrieves plans with limit' do
    101.times do | i|
      stripe_helper.create_plan(id: "Plan #{i}", amount: 11)
    end
    all = Stripe::Plan.all(limit: 100)

    expect(all.count).to eq(100)
  end

  describe "Validation", :live => true do
    let(:params) { stripe_helper.create_plan_params }
    let(:subject) { Stripe::Plan.create(params) }

    describe "Required Parameters" do
      after do
        params.delete(@name)
        message =
          if @name == :amount
            "Plans require an `#{@name}` parameter to be set."
          else
            "Missing required param: #{@name}."
          end
        expect { subject }.to raise_error(Stripe::InvalidRequestError, message)
      end

      it("validates presence of interval") { @name = :interval }
      it("validates presence of currency") { @name = :currency }
      it("validates presence of product") { @name = :product }
      it("validates presence of amount") { @name = :amount }
    end

    describe "Inclusion" do
      let(:invalid_currency_message) {
        ""
      }

      it "validates inclusion of interval in a supported list'" do
        expect {
          Stripe::Product.create(params.merge({interval: "OOPS"}))
        }.to raise_error(Stripe::InvalidRequestError, "Invalid interval: must be one of month, year, week, or day")
      end

      it "validates inclusion of currency in a supported list" do
        expect {
          Stripe::Product.create(params.merge({currency: "OOPS"}))
        }.to raise_error(Stripe::InvalidRequestError, invalid_currency_message)
      end
    end

    describe "Integer" do
      it 'validates amount is an integer' do
        expect {
          Stripe::Plan.create(plan_attributes.merge({amount: 99.99}))
        }.to raise_error(Stripe::InvalidRequestError, "Invalid integer: 99.99")
      end
    end

    describe "Associations" do
      it "validates associated product" do
        expect { plan }.to raise_error(Stripe::InvalidRequestError, "Invalid integer: 99.99")
      end
    end

    describe "Uniqueness" do
      it "validates for uniqueness" do
        stripe_helper.delete_plan(params[:id])

        Stripe::Plan.create(params)
        expect {
          Stripe::Plan.create(params)
        }.to raise_error(Stripe::InvalidRequestError, "Plan already exists.")
      end
    end

  end

end
