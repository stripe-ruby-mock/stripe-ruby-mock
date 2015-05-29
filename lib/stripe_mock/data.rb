module StripeMock
  module Data

    def self.mock_account(params = {})
      id = params[:id] || 'acct_103ED82ePvKYlo2C'
      {
        id: id,
        email: "bob@example.com",
        statement_descriptor: nil,
        display_name: "Stripe.com",
        timezone: "US/Pacific",
        details_submitted: false,
        charges_enabled: false,
        transfers_enabled: false,
        currencies_supported: [
          "usd"
        ],

      }.merge(params)
    end

    def self.mock_customer(sources, params)
      cus_id = params[:id] || "test_cus_default"
      sources.each {|source| source[:customer] = cus_id}
      {
        email: 'stripe_mock@example.com',
        description: 'an auto-generated stripe customer data mock',
        object: "customer",
        created: 1372126710,
        id: cus_id,
        livemode: false,
        delinquent: false,
        discount: nil,
        account_balance: 0,
        sources: {
          object: "list",
          total_count: sources.size,
          url: "/v1/customers/#{cus_id}/sources",
          data: sources
        },
        subscriptions: {
          object: "list",
          total_count: 0,
          url: "/v1/customers/#{cus_id}/subscriptions",
          data: []
        },
        default_source: nil
      }.merge(params)
    end

    def self.mock_charge(params={})
      charge_id = params[:id] || "ch_1fD6uiR9FAA2zc"
      {
        id: charge_id,
        object: "charge",
        created: 1366194027,
        livemode: false,
        paid: true,
        amount: 0,
        currency: "usd",
        refunded: false,
        fee: 0,
        status: 'succeeded',
        fee_details: [
        ],
        source: {
          object: "card",
          last4: "4242",
          type: "Visa",
          brand: "Visa",
          funding: "credit",
          exp_month: 12,
          exp_year: 2013,
          fingerprint: "3TQGpK9JoY1GgXPw",
          country: "US",
          name: "name",
          address_line1: nil,
          address_line2: nil,
          address_city: nil,
          address_state: nil,
          address_zip: nil,
          address_country: nil,
          cvc_check: nil,
          address_line1_check: nil,
          address_zip_check: nil
        },
        captured: params.has_key?(:capture) ? params.delete(:capture) : true,
        refunds: {
          object: "list",
          total_count: 0,
          has_more: false,
          url: "/v1/charges/#{charge_id}/refunds",
          data: []
        },
        balance_transaction: "txn_2dyYXXP90MN26R",
        failure_message: nil,
        failure_code: nil,
        amount_refunded: 0,
        customer: nil,
        invoice: nil,
        description: nil,
        dispute: nil,
        metadata: {
        }
      }.merge(params)
    end

    def self.mock_refund(params={})
      {
        id: "re_4fWhgUh5si7InF",
        amount: 1,
        currency: "usd",
        created: 1409165988,
        object: "refund",
        balance_transaction: "txn_4fWh2RKvgxcXqV",
        metadata: {},
        charge: "ch_4fWhYjzQ23UFWT"
      }.merge(params)
    end

    def self.mock_charge_array
      {
        :data => [test_charge, test_charge, test_charge],
        :object => 'list',
        :url => '/v1/charges'
      }
    end

    def self.mock_card(params={})
      StripeMock::Util.card_merge({
        id: "test_cc_default",
        object: "card",
        last4: "4242",
        type: "Visa",
        brand: "Visa",
        funding: "credit",
        exp_month: 4,
        exp_year: 2016,
        fingerprint: "wXWJT135mEK107G8",
        customer: "test_cus_default",
        country: "US",
        name: "Johnny App",
        address_line1: nil,
        address_line2: nil,
        address_city: nil,
        address_state: nil,
        address_zip: nil,
        address_country: nil,
        cvc_check: nil,
        address_line1_check: nil,
        address_zip_check: nil
      }, params)
    end

    def self.mock_bank_account(params={})
      {
        object: "bank_account",
        bank_name: "STRIPEMOCK TEST BANK",
        last4: "6789",
        country: "US",
        currency: "usd",
        validated: false,
        fingerprint: "aBcFinGerPrINt123"
      }.merge(params)
    end

    def self.mock_coupon(params={})
      {
        :duration_in_months => 3,
        :percent_off => 25,
        :amount_off => nil,
        :currency => nil,
        :id => "co_test_coupon",
        :object => "coupon",
        :max_redemptions => nil,
        :redeem_by => nil,
        :times_redeemed => 0,
        :valid => true,
        :metadata => {},
      }.merge(params)
    end

    #FIXME nested overrides would be better than hardcoding plan_id
    def self.mock_subscription(params={})
      StripeMock::Util.rmerge({
        :current_period_start => 1308595038,
        :current_period_end => 1308681468,
        :status => "trialing",
        :plan => {
          :interval => "month",
          :amount => 7500,
          :trial_period_days => 30,
          :object => "plan",
          :id => '__test_plan_id__'
        },
        :cancel_at_period_end => false,
        :canceled_at => nil,
        :ended_at => nil,
        :start => 1308595038,
        :object => "subscription",
        :trial_start => 1308595038,
        :trial_end => 1308681468,
        :customer => "c_test_customer",
        :quantity => 1,
        :tax_percent => nil,
        :discount => nil,
        :metadata => {}
      }, params)
    end

    def self.mock_invoice(lines, params={})
      in_id = params[:id] || "test_in_default"
      lines << Data.mock_line_item() if lines.empty?
      {
        id: 'in_test_invoice',
        date: 1349738950,
        period_end: 1349738950,
        period_start: 1349738950,
        lines: {
          object: "list",
          total_count: lines.count,
          url: "/v1/invoices/#{in_id}/lines",
          data: lines
        },
        subtotal: lines.map {|line| line[:amount]}.reduce(0, :+),
        total: lines.map {|line| line[:amount]}.reduce(0, :+),
        customer: "test_customer",
        object: 'invoice',
        attempted: false,
        closed: false,
        forgiven: false,
        paid: false,
        livemode: false,
        attempt_count: 0,
        amount_due: lines.map {|line| line[:amount]}.reduce(0, :+),
        currency: 'usd',
        starting_balance: 0,
        ending_balance: nil,
        next_payment_attempt: 1349825350,
        charge: nil,
        discount: nil,
        subscription: nil
      }.merge(params)
    end

    def self.mock_line_item(params = {})
      {
        id: "ii_test",
        object: "line_item",
        type: "invoiceitem",
        livemode: false,
        amount: 1000,
        currency: "usd",
        proration: false,
        period: {
          start: 1349738920,
          end: 1349738920
        },
        quantity: nil,
        plan: nil,
        description: "Test invoice item",
        metadata: {}
      }.merge(params)
    end

    def self.mock_invoice_item(params = {})
      {
        id: "test_ii",
        object: "invoiceitem",
        date: 1349738920,
        amount: 1099,
        livemode: false,
        proration: false,
        currency: "usd",
        customer: "cus_test",
        description: "invoice item desc",
        metadata: {},
        invoice: nil,
        subscription: nil
      }.merge(params)
    end

    def self.mock_paid_invoice
      test_invoice.merge({
          :attempt_count => 1,
          :attempted => true,
          :closed => true,
          :paid => true,
          :charge => 'ch_test_charge',
          :ending_balance => 0,
          :next_payment_attempt => nil,
        })
    end

    def self.mock_invoice_customer_array
      {
        :data => [test_invoice],
        :object => 'list',
        :url => '/v1/invoices?customer=test_customer'
      }
    end

    def self.mock_plan(params={})
      {
        interval: "month",
        name: "The Basic Plan",
        amount: 2300,
        currency: "usd",
        id: "2",
        object: "plan",
        livemode: false,
        interval_count: 1,
        trial_period_days: nil
      }.merge(params)
    end

    def self.mock_recipient(cards, params={})
      rp_id = params[:id] || "test_rp_default"
      cards.each {|card| card[:recipient] = rp_id}
      {
        name: "Stripe User",
        type: "individual",
        livemode: false,
        object: "recipient",
        id: rp_id,
        active_account: {
          last4: "6789",
          bank_name: "STRIPE TEST BANK",
          country: "US",
          object: "bank_account"
        },
        created: 1304114758,
        verified: true,
        metadata: {
        },
        cards: {
          object: "list",
          url: "/v1/recipients/#{rp_id}/cards",
          data: cards,
          total_count: cards.count
        },
        default_card: nil
      }.merge(params)
    end

    def self.mock_recipient_array
      {
        :data => [test_recipient, test_recipient, test_recipient],
        :object => 'list',
        :url => '/v1/recipients'
      }
    end

    def self.mock_token(params={})
      {
        :id => 'tok_default',
        :livemode => false,
        :used => false,
        :object => 'token',
        :type => 'card',
        :card => {
          :id => 'card_default',
          :object => 'card',
          :last4 => '2222',
          :type => 'Visa',
          :brand => 'Visa',
          :funding => 'credit',
          :exp_month => 9,
          :exp_year => 2017,
          :fingerprint => 'JRRLXGh38NiYygM7',
          :customer => nil,
          :country => 'US',
          :name => nil,
          :address_line1 => nil,
          :address_line2 => nil,
          :address_city => nil,
          :address_state => nil,
          :address_zip => nil,
          :address_country => nil
        }
      }.merge(params)
    end

    def self.mock_transfer(params={})
      id = params[:id] || 'tr_test_transfer'
      {
        :status => 'pending',
        :amount => 100,
        :account => {
          :object => 'bank_account',
          :country => 'US',
          :bank_name => 'STRIPE TEST BANK',
          :last4 => '6789'
        },
        :recipient => 'test_recipient',
        :fee => 0,
        :fee_details => [],
        :id => id,
        :livemode => false,
        :currency => "usd",
        :object => "transfer",
        :date => 1304114826,
        :description => "Transfer description",
        :reversed => false,
        :reversals => {
          :object => "list",
          :total_count => 0,
          :has_more => false,
          :url => "/v1/transfers/#{id}/reversals"
        },
      }.merge(params)
    end

    def self.mock_transfer_array
      {
        :data => [test_transfer, test_transfer, test_transfer],
        :object => 'list',
        :url => '/v1/transfers'
      }
    end

    def self.mock_invalid_api_key_error
      {
        "error" => {
          "type" => "invalid_request_error",
          "message" => "Invalid API Key provided: invalid"
        }
      }
    end

    def self.mock_invalid_exp_year_error
      {
        "error" => {
          "code" => "invalid_expiry_year",
          "param" => "exp_year",
          "type" => "card_error",
          "message" => "Your card's expiration year is invalid"
        }
      }
    end

    def self.mock_missing_id_error
      {
        :error => {
          :param => "id",
          :type => "invalid_request_error",
          :message => "Missing id"
        }
      }
    end

    def self.mock_delete_subscription(params={})
      {
        deleted: true
      }.merge(params)
    end

    def self.mock_api_error
      {
        :error => {
          :type => "api_error"
        }
      }
    end

    def self.mock_delete_discount_response
      {
        :deleted => true,
        :id => "di_test_coupon"
      }
    end

    def self.mock_list_object(data, params = {})
      list = StripeMock::Data::List.new(data, params)
      list.to_h
    end
  end
end
