require 'spec_helper'

shared_examples 'Plan API' do

  it "creates a stripe plan" do
    plan = Stripe::Plan.create(
      :id => 'pid_1',
      :name => 'The Mock Plan',
      :amount => 9900,
      :currency => 'USD',
      :interval => 1,
      :trial_period_days => 30
    )

    expect(plan.id).to eq('pid_1')
    expect(plan.name).to eq('The Mock Plan')
    expect(plan.amount).to eq(9900)

    expect(plan.currency).to eq('USD')
    expect(plan.interval).to eq(1)
    expect(plan.trial_period_days).to eq(30)
  end


  it "stores a created stripe plan in memory" do
    plan = Stripe::Plan.create(
      :id => 'pid_2',
      :name => 'The Memory Plan',
      :amount => 1100,
      :currency => 'USD',
      :interval => 1
    )
    plan2 = Stripe::Plan.create(
      :id => 'pid_3',
      :name => 'The Bonk Plan',
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
    original = Stripe::Plan.create({
      amount: 1331
    })
    plan = Stripe::Plan.retrieve(original.id)

    expect(plan.id).to eq(original.id)
    expect(plan.amount).to eq(original.amount)
  end


  it "retrieves a stripe plan with an id that doesn't exist" do
    plan = Stripe::Plan.retrieve('test_charge_x')

    expect(plan.id).to eq('test_charge_x')
    expect(plan.amount).to_not be_nil
    expect(plan.name).to_not be_nil

    expect(plan.currency).to_not be_nil
    expect(plan.interval).to_not be_nil
  end

  it "retrieves all plans" do
    Stripe::Plan.create({ id: 'Plan One', amount: 54321 })
    Stripe::Plan.create({ id: 'Plan Two', amount: 98765 })

    all = Stripe::Plan.all
    expect(all.length).to eq(2)
    all.map(&:id).should include('Plan One', 'Plan Two')
    all.map(&:amount).should include(54321, 98765)
  end

end
