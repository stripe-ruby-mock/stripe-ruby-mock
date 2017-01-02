require 'spec_helper'

shared_examples 'Charge API' do

  it "requires a valid card token", :live => true do
    expect {
      charge = Stripe::Charge.create(
        amount: 99,
        currency: 'usd',
        source: 'bogus_card_token'
      )
    }.to raise_error(Stripe::InvalidRequestError, /token/i)
  end

  it "requires a valid customer or source", :live => true do
    expect {
      charge = Stripe::Charge.create(
        amount: 99,
        currency: 'usd',
      )
    }.to raise_error(Stripe::InvalidRequestError, /Must provide source or customer/i)
  end

  it "requires presence of amount", :live => true do
    expect {
      charge = Stripe::Charge.create(
        currency: 'usd',
        source: stripe_helper.generate_card_token
      )
    }.to raise_error(Stripe::InvalidRequestError, /missing required param: amount/i)
  end

  it "requires presence of currency", :live => true do
    expect {
      charge = Stripe::Charge.create(
        amount: 99,
        source: stripe_helper.generate_card_token
      )
    }.to raise_error(Stripe::InvalidRequestError, /missing required param: currency/i)
  end

  it "requires a valid positive amount", :live => true do
    expect {
      charge = Stripe::Charge.create(
        amount: -99,
        currency: 'usd',
        source: stripe_helper.generate_card_token
      )
    }.to raise_error(Stripe::InvalidRequestError, /invalid positive integer/i)
  end

  it "requires a valid integer amount", :live => true do
    expect {
      charge = Stripe::Charge.create(
        amount: 99.0,
        currency: 'usd',
        source: stripe_helper.generate_card_token
      )
    }.to raise_error(Stripe::InvalidRequestError, /invalid integer/i)
  end

  it "creates a stripe charge item with a card token" do
    charge = Stripe::Charge.create(
      amount: 999,
      currency: 'USD',
      source: stripe_helper.generate_card_token,
      description: 'card charge'
    )

    expect(charge.id).to match(/^test_ch/)
    expect(charge.amount).to eq(999)
    expect(charge.description).to eq('card charge')
    expect(charge.captured).to eq(true)
    expect(charge.status).to eq('succeeded')
  end

  it "creates a stripe charge item with a bank token" do
    charge = Stripe::Charge.create(
      amount: 999,
      currency: 'USD',
      source: stripe_helper.generate_bank_token,
      description: 'bank charge'
    )

    expect(charge.id).to match(/^test_ch/)
    expect(charge.amount).to eq(999)
    expect(charge.description).to eq('bank charge')
    expect(charge.captured).to eq(true)
    expect(charge.status).to eq('succeeded')
  end

  it 'creates a stripe charge item with a customer', :live => true do
    customer = Stripe::Customer.create({
      email: 'johnny@appleseed.com',
      source: stripe_helper.generate_card_token(number: '4012888888881881', address_city: 'LA'),
      description: "a description"
    })

    expect(customer.sources.data.length).to eq(1)
    expect(customer.sources.data[0].id).not_to be_nil
    expect(customer.sources.data[0].last4).to eq('1881')

    charge = Stripe::Charge.create(
      amount: 999,
      currency: 'USD',
      customer: customer.id,
      description: 'a charge with a specific customer'
    )

    expect(charge.id).to match(/^(test_)?ch/)
    expect(charge.amount).to eq(999)
    expect(charge.description).to eq('a charge with a specific customer')
    expect(charge.captured).to eq(true)
    expect(charge.source.last4).to eq('1881')
    expect(charge.source.address_city).to eq('LA')
  end

  it "creates a stripe charge item with a customer and card id" do
    customer = Stripe::Customer.create({
      email: 'johnny@appleseed.com',
      source: stripe_helper.generate_card_token(number: '4012888888881881'),
      description: "a description"
    })

    expect(customer.sources.data.length).to eq(1)
    expect(customer.sources.data[0].id).not_to be_nil
    expect(customer.sources.data[0].last4).to eq('1881')

    card   = customer.sources.data[0]
    charge = Stripe::Charge.create(
      amount: 999,
      currency: 'USD',
      customer: customer.id,
      source: card.id,
      description: 'a charge with a specific card'
    )

    expect(charge.id).to match(/^test_ch/)
    expect(charge.amount).to eq(999)
    expect(charge.description).to eq('a charge with a specific card')
    expect(charge.captured).to eq(true)
    expect(charge.source.last4).to eq('1881')
  end


  it "stores a created stripe charge in memory" do
    charge = Stripe::Charge.create({
      amount: 333,
      currency: 'USD',
      source: stripe_helper.generate_card_token
    })
    charge2 = Stripe::Charge.create({
      amount: 777,
      currency: 'USD',
      source: stripe_helper.generate_card_token
    })
    data = test_data_source(:charges)
    expect(data[charge.id]).to_not be_nil
    expect(data[charge.id][:amount]).to eq(333)

    expect(data[charge2.id]).to_not be_nil
    expect(data[charge2.id][:amount]).to eq(777)
  end

  describe 'balance transaction for charge' do
    it "creates a balance transaction by default" do
      charge = Stripe::Charge.create({
        amount: 300,
        currency: 'USD',
        source: stripe_helper.generate_card_token
      })
      bal_trans = Stripe::BalanceTransaction.retrieve(charge.balance_transaction)
      expect(bal_trans.amount).to eq(charge.amount)
      expect(bal_trans.fee).to eq(39)
      expect(bal_trans.net).to eq(261)
      expect(bal_trans.source).to eq(charge.id)
    end

    it "creates a balance transaction if capture requested" do
      charge = Stripe::Charge.create({
        amount: 1000,
        currency: 'USD',
        source: stripe_helper.generate_card_token,
        capture: true
      })
      # This is identical to previous test ("creates a balance transaction by default") which checks all amounts so only
      # verify the balance transaction exists here
      expect(charge.balance_transaction).not_to eq(nil)
    end

    it "does not create a balance transaction if charge not captured" do
      charge = Stripe::Charge.create({
        amount: 1500,
        currency: 'USD',
        source: stripe_helper.generate_card_token,
        capture: false
      })
      expect(charge.balance_transaction).to eq(nil)
    end

    it "creates a balance transaction when existing uncaptured charge is captured" do
      charge = Stripe::Charge.create({
        amount: 2000,
        currency: 'USD',
        source: stripe_helper.generate_card_token,
        capture: false
      })
      expect(charge.balance_transaction).to eq(nil)
      expect(charge.captured).to eq(false)
      charge.capture({ amount: 2000 })
      bal_trans = Stripe::BalanceTransaction.retrieve(charge.balance_transaction)
      expect(bal_trans.amount).to eq(charge.amount)
      expect(bal_trans.fee).to eq(88)
      expect(bal_trans.net).to eq(1912)
      expect(bal_trans.source).to eq(charge.id)
    end
  end

  context 'application fee for customer charge in managed account' do
    before do
      @account = Stripe::Account.create(managed: true, country: 'US')
      @customer = Stripe::Customer.create({
        email: 'johnny@appleseed.com',
        source: stripe_helper.generate_card_token
      }, {stripe_account: @account.id})
    end

    it "creates an application fee for customer charge by default" do
      charge = Stripe::Charge.create({
        amount: 2000,
        currency: 'USD',
        customer: @customer,
        application_fee: 100
      }, {stripe_account: @account.id})

      app_fee = Stripe::ApplicationFee.retrieve(charge.application_fee)
      expect(app_fee.amount).to eq(100)
      expect(app_fee.account).to eq(@account.id)
      expect(app_fee.charge).to eq(charge.id)

      bal_trans = Stripe::BalanceTransaction.retrieve(charge.balance_transaction, {stripe_account: @account})
      expect(bal_trans.amount).to eq(charge.amount)
      expect(bal_trans.fee).to eq(188)  # note that fee includes Stripe processing fee as well as application fee
      expect(bal_trans.net).to eq(1812)

      # also verify balance transaction created for the application fee
      app_fee_bal_trans = Stripe::BalanceTransaction.retrieve(app_fee.balance_transaction)
      expect(app_fee_bal_trans.amount).to eq(app_fee.amount)
      expect(app_fee_bal_trans.fee).to eq(0)
      expect(app_fee_bal_trans.net).to eq(app_fee.amount)
      expect(app_fee_bal_trans.source).to eq(app_fee.id)
    end

    it "creates an application fee for customer charge if capture requested" do
      charge = Stripe::Charge.create({
        amount: 2000,
        currency: 'USD',
        customer: @customer,
        application_fee: 100,
        capture: true
      }, {stripe_account: @account.id})

      # This is identical to previous test ("creates an application fee for customer charge by default") which checks all amounts so only
      # verify the application fee and balance transactions exist here
      app_fee = Stripe::ApplicationFee.retrieve(charge.application_fee)
      expect(app_fee).not_to eq(nil)
      expect(app_fee.balance_transaction).not_to eq(nil)
    end

    it "does not create an application fee for customer charge if charge not captured" do
      charge = Stripe::Charge.create({
        amount: 2000,
        currency: 'USD',
        customer: @customer,
        application_fee: 100,
        capture: false
      }, {stripe_account: @account.id})

      expect(charge.application_fee).to eq(nil)
    end

    it "creates an application fee for customer charge when existing uncaptured charge is captured with no updated application fee amount" do
      charge = Stripe::Charge.create({
        amount: 3000,
        currency: 'USD',
        customer: @customer,
        application_fee: 200,
        capture: false
      }, {stripe_account: @account.id})
      expect(charge.application_fee).to eq(nil)
      expect(charge.captured).to eq(false)
      charge.capture({ amount: 3000 })

      app_fee = Stripe::ApplicationFee.retrieve(charge.application_fee)
      expect(app_fee.amount).to eq(200)
      expect(app_fee.account).to eq(@account.id)
      expect(app_fee.charge).to eq(charge.id)

      bal_trans = Stripe::BalanceTransaction.retrieve(charge.balance_transaction, {stripe_account: @account})
      expect(bal_trans.amount).to eq(charge.amount)
      expect(bal_trans.fee).to eq(317)  # note that fee includes Stripe processing fee as well as application fee
      expect(bal_trans.net).to eq(2683)

      # also verify balance transaction created for the application fee
      app_fee_bal_trans = Stripe::BalanceTransaction.retrieve(app_fee.balance_transaction)
      expect(app_fee_bal_trans.amount).to eq(app_fee.amount)
      expect(app_fee_bal_trans.fee).to eq(0)
      expect(app_fee_bal_trans.net).to eq(app_fee.amount)
      expect(app_fee_bal_trans.source).to eq(app_fee.id)
    end

    it "creates an application fee for customer charge when existing uncaptured charge is captured with updated application fee amount" do
      charge = Stripe::Charge.create({
        amount: 4000,
        currency: 'USD',
        customer: @customer,
        application_fee: 500,
        capture: false
      }, {stripe_account: @account.id})
      expect(charge.application_fee).to eq(nil)
      expect(charge.captured).to eq(false)
      charge.capture({ amount: 4000, application_fee: 1700 })

      app_fee = Stripe::ApplicationFee.retrieve(charge.application_fee)
      expect(app_fee.amount).to eq(1700)
      expect(app_fee.account).to eq(@account.id)
      expect(app_fee.charge).to eq(charge.id)

      bal_trans = Stripe::BalanceTransaction.retrieve(charge.balance_transaction, {stripe_account: @account})
      expect(bal_trans.amount).to eq(charge.amount)
      expect(bal_trans.fee).to eq(1846)  # note that fee includes Stripe processing fee as well as application fee
      expect(bal_trans.net).to eq(2154)

      # also verify balance transaction created for the application fee
      app_fee_bal_trans = Stripe::BalanceTransaction.retrieve(app_fee.balance_transaction)
      expect(app_fee_bal_trans.amount).to eq(app_fee.amount)
      expect(app_fee_bal_trans.fee).to eq(0)
      expect(app_fee_bal_trans.net).to eq(app_fee.amount)
      expect(app_fee_bal_trans.source).to eq(app_fee.id)
    end

  end

  it "can expand balance transaction" do
    charge = Stripe::Charge.create({
      amount: 300,
      currency: 'USD',
      source: stripe_helper.generate_card_token,
      expand: ['balance_transaction']
    })
    expect(charge.balance_transaction).to be_a(Stripe::BalanceTransaction)
  end

  it "retrieves a stripe charge" do
    original = Stripe::Charge.create({
      amount: 777,
      currency: 'USD',
      source: stripe_helper.generate_card_token
    })
    charge = Stripe::Charge.retrieve(original.id)

    expect(charge.id).to eq(original.id)
    expect(charge.amount).to eq(original.amount)
  end

  it "cannot retrieve a charge that doesn't exist" do
    expect { Stripe::Charge.retrieve('nope') }.to raise_error {|e|
      expect(e).to be_a Stripe::InvalidRequestError
      expect(e.param).to eq('charge')
      expect(e.http_status).to eq(404)
    }
  end

  it "updates a stripe charge" do
    original = Stripe::Charge.create({
      amount: 777,
      currency: 'USD',
      source: stripe_helper.generate_card_token,
      description: 'Original description',
    })
    charge = Stripe::Charge.retrieve(original.id)

    charge.description = "Updated description"
    charge.metadata[:receipt_id] = 1234
    charge.receipt_email = "newemail@email.com"
    charge.fraud_details = {"user_report" => "safe"}
    charge.save

    updated = Stripe::Charge.retrieve(original.id)

    expect(updated.description).to eq(charge.description)
    expect(updated.metadata.to_hash).to eq(charge.metadata.to_hash)
    expect(updated.receipt_email).to eq(charge.receipt_email)
    expect(updated.fraud_details.to_hash).to eq(charge.fraud_details.to_hash)
  end

  it "marks a charge as safe" do
    original = Stripe::Charge.create({
      amount: 777,
      currency: 'USD',
      source: stripe_helper.generate_card_token
    })
    charge = Stripe::Charge.retrieve(original.id)

    charge.mark_as_safe

    updated = Stripe::Charge.retrieve(original.id)
    expect(updated.fraud_details[:user_report]).to eq "safe"
  end

  it "does not lose data when updating a charge" do
    original = Stripe::Charge.create({
      amount: 777,
      currency: 'USD',
      source: stripe_helper.generate_card_token,
      metadata: {:foo => "bar"}
    })
    original.metadata[:receipt_id] = 1234
    original.save

    updated = Stripe::Charge.retrieve(original.id)

    expect(updated.metadata[:foo]).to eq "bar"
    expect(updated.metadata[:receipt_id]).to eq 1234
  end

  it "disallows most parameters on updating a stripe charge" do
    original = Stripe::Charge.create({
      amount: 777,
      currency: 'USD',
      source: stripe_helper.generate_card_token,
      description: 'Original description',
    })

    charge = Stripe::Charge.retrieve(original.id)
    charge.currency = "CAD"
    charge.amount = 777
    charge.source = {any: "source"}

    expect { charge.save }.to raise_error(Stripe::InvalidRequestError) do |error|
      expect(error.message).to match(/Received unknown parameters/)
      expect(error.message).to match(/currency/)
      expect(error.message).to match(/amount/)
      expect(error.message).to match(/source/)
    end
  end


  it "creates a unique balance transaction" do
    charge1 = Stripe::Charge.create(
      amount: 999,
      currency: 'USD',
      source: stripe_helper.generate_card_token,
      description: 'card charge'
    )

    charge2 = Stripe::Charge.create(
      amount: 999,
      currency: 'USD',
      source: stripe_helper.generate_card_token,
      description: 'card charge'
    )

    expect(charge1.balance_transaction).not_to eq(charge2.balance_transaction)
  end

  context "retrieving a list of charges" do
    before do
      @customer = Stripe::Customer.create(email: 'johnny@appleseed.com')
      @customer2 = Stripe::Customer.create(email: 'johnny2@appleseed.com')
      @charge = Stripe::Charge.create(amount: 1, currency: 'usd', customer: @customer.id)
      @charge2 = Stripe::Charge.create(amount: 1, currency: 'usd', customer: @customer2.id)
    end

    it "stores charges for a customer in memory" do
      expect(@customer.charges.data.map(&:id)).to eq([@charge.id])
    end

    it "stores all charges in memory" do
      expect(Stripe::Charge.all.data.map(&:id)).to eq([@charge.id, @charge2.id])
    end

    it "defaults count to 10 charges" do
      11.times { Stripe::Charge.create(amount: 1, currency: 'usd', source: stripe_helper.generate_card_token) }

      expect(Stripe::Charge.all.data.count).to eq(10)
    end

    it "is marked as having more when more objects exist" do
      11.times { Stripe::Charge.create(amount: 1, currency: 'usd', source: stripe_helper.generate_card_token) }

      expect(Stripe::Charge.all.has_more).to eq(true)
    end

    context "when passing limit" do
      it "gets that many charges" do
        expect(Stripe::Charge.all(limit: 1).count).to eq(1)
      end
    end
  end

  it 'when use starting_after param', live: true do
    cus = Stripe::Customer.create(
        description: 'Customer for test@example.com',
        source: {
            object: 'card',
            number: '4242424242424242',
            exp_month: 12,
            exp_year: 2024,
            cvc: 123
        }
    )
    12.times do
      Stripe::Charge.create(customer: cus.id, amount: 100, currency: "usd")
    end

    all = Stripe::Charge.all
    default_limit = 10
    half = Stripe::Charge.all(starting_after: all.data.at(1).id)

    expect(half).to be_a(Stripe::ListObject)
    expect(half.data.count).to eq(default_limit)
    expect(half.data.first.id).to eq(all.data.at(2).id)
  end


  describe 'captured status value' do
    it "reports captured by default" do
      charge = Stripe::Charge.create({
        amount: 777,
        currency: 'USD',
        source: stripe_helper.generate_card_token
      })

      expect(charge.captured).to eq(true)
    end

    it "reports captured if capture requested" do
      charge = Stripe::Charge.create({
        amount: 777,
        currency: 'USD',
        source: stripe_helper.generate_card_token,
        capture: true
      })

      expect(charge.captured).to eq(true)
    end

    it "reports not captured if capture: false requested" do
      charge = Stripe::Charge.create({
        amount: 777,
        currency: 'USD',
        source: stripe_helper.generate_card_token,
        capture: false
      })

      expect(charge.captured).to eq(false)
    end
  end

  describe "two-step charge (auth, then capture)" do
    it "changes captured status upon #capture" do
      charge = Stripe::Charge.create({
        amount: 777,
        currency: 'USD',
        source: stripe_helper.generate_card_token,
        capture: false
      })

      returned_charge = charge.capture
      expect(charge.captured).to eq(true)
      expect(returned_charge.id).to eq(charge.id)
      expect(returned_charge.captured).to eq(true)
    end

    it "captures with specified amount" do
      charge = Stripe::Charge.create({
        amount: 777,
        currency: 'USD',
        source: stripe_helper.generate_card_token,
        capture: false
      })

      returned_charge = charge.capture({ amount: 677, application_fee: 123 })
      expect(charge.captured).to eq(true)
      expect(returned_charge.amount_refunded).to eq(100)
      application_fee = Stripe::ApplicationFee.retrieve(returned_charge.application_fee)
      expect(application_fee.amount).to eq(123)
      expect(returned_charge.id).to eq(charge.id)
      expect(returned_charge.captured).to eq(true)
    end
  end

  describe "idempotency" do
    let(:customer) { Stripe::Customer.create(email: 'johnny@appleseed.com') }
    let(:idempotent_charge_params) {{
      amount: 777,
      currency: 'USD',
      customer: customer.id,
      capture: true,
      idempotency_key: 'onceisenough'
    }}

    it "returns the original charge if the same idempotency_key is passed in" do
      charge1 = Stripe::Charge.create(idempotent_charge_params)
      charge2 = Stripe::Charge.create(idempotent_charge_params)

      expect(charge1).to eq(charge2)
    end

    it "returns different charges if different idempotency_keys are used for each charge" do
      idempotent_charge_params2 = idempotent_charge_params.clone
      idempotent_charge_params2[:idempotency_key] = 'thisoneisdifferent'

      charge1 = Stripe::Charge.create(idempotent_charge_params)
      charge2 = Stripe::Charge.create(idempotent_charge_params2)

      expect(charge1).not_to eq(charge2)
    end
  end

end
