module StripeMock
  module Data

    def self.test_customer(params)
      {
        email: 'stripe_mock@example.com',
        description: 'an auto-generated stripe customer data mock',
        object: "customer",
        created: 1372126710,
        id: "cus_24vuDSooAnB087",
        livemode: false,
        active_card: {
          object: "card",
          last4: "4242",
          type: "Visa",
          exp_month: 12,
          exp_year: 2013,
          fingerprint: "wXWJT135mEK107G8",
          country: "US",
          name: "Vetty Vet",
          address_line1: nil,
          address_line2: nil,
          address_city: nil,
          address_state: nil,
          address_zip: nil,
          address_country: nil,
          cvc_check: "pass",
          address_line1_check: nil,
          address_zip_check: nil
        },
        delinquent: false,
        subscription: nil,
        discount: nil,
        account_balance: 0
      }.merge(params)
    end

    def self.test_charge(params={})
      {
        id: "ch_1fD6uiR9FAA2zc",
        object: "charge",
        created: 1366194027,
        livemode: false,
        paid: true,
        amount: 0,
        currency: "usd",
        refunded: false,
        fee: 0,
        fee_details: [
        ],
        card: {
          object: "card",
          last4: "4242",
          type: "Visa",
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
        captured: params.has_key?(:capture) ? params[:capture] : true,
        failure_message: nil,
        amount_refunded: 0,
        customer: nil,
        invoice: nil,
        description: nil,
        dispute: nil
      }.merge(params)
    end

    def self.test_charge_array
      {
        :data => [test_charge, test_charge, test_charge],
        :object => 'list',
        :url => '/v1/charges'
      }
    end

    def self.test_card(params={})
      {
        :type => "Visa",
        :last4 => "4242",
        :exp_month => 11,
        :country => "US",
        :exp_year => 2012,
        :id => "cc_test_card",
        :object => "card"
      }.merge(params)
    end

    def self.test_coupon(params={})
      {
        :duration => 'repeating',
        :duration_in_months => 3,
        :percent_off => 25,
        :id => "co_test_coupon",
        :object => "coupon"
      }.merge(params)
    end

    #FIXME nested overrides would be better than hardcoding plan_id
    def self.test_subscription(params={})
      StripeMock::Util.rmerge({
        :current_period_end => 1308681468,
        :status => "trialing",
        :plan => {
          :interval => "month",
          :amount => 7500,
          :trial_period_days => 30,
          :object => "plan",
          :id => '__test_plan_id__'
        },
        :current_period_start => 1308595038,
        :cancel_at_period_end => false,
        :canceled_at => nil,
        :start => 1308595038,
        :object => "subscription",
        :trial_start => 1308595038,
        :trial_end => 1308681468,
        :customer => "c_test_customer",
        :quantity => 1
      }, params)
    end

    def self.test_invoice(params={})
      {
        :id => 'in_test_invoice',
        :object => 'invoice',
        :livemode => false,
        :amount_due => 1000,
        :attempt_count => 0,
        :attempted => false,
        :closed => false,
        :currency => 'usd',
        :customer => 'c_test_customer',
        :date => 1349738950,
        :lines => {
          "invoiceitems" => [
            {
              :id => 'ii_test_invoice_item',
              :object => '',
              :livemode => false,
              :amount => 1000,
              :currency => 'usd',
              :customer => 'c_test_customer',
              :date => 1349738950,
              :description => "A Test Invoice Item",
              :invoice => 'in_test_invoice'
            },
          ],
        },
        :paid => false,
        :period_end => 1349738950,
        :period_start => 1349738950,
        :starting_balance => 0,
        :subtotal => 1000,
        :total => 1000,
        :charge => nil,
        :discount => nil,
        :ending_balance => nil,
        :next_payemnt_attempt => 1349825350,
      }.merge(params)
    end

    def self.test_paid_invoice
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

    def self.test_invoice_customer_array
      {
        :data => [test_invoice],
        :object => 'list',
        :url => '/v1/invoices?customer=test_customer'
      }
    end

    def self.test_plan(params={})
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

    def self.test_recipient(params={})
      {
        :name => "Stripe User",
        :type => "individual",
        :livemode => false,
        :object => "recipient",
        :id => "rp_test_recipient",
        :active_account => {
          :last4 => "6789",
          :bank_name => "STRIPE TEST BANK",
          :country => "US",
          :object => "bank_account"
        },
        :created => 1304114758,
        :verified => true
      }.merge(params)
    end

    def self.test_recipient_array
      {
        :data => [test_recipient, test_recipient, test_recipient],
        :object => 'list',
        :url => '/v1/recipients'
      }
    end

    def self.test_transfer(params={})
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
        :id => "tr_test_transfer",
        :livemode => false,
        :currency => "usd",
        :object => "transfer",
        :date => 1304114826
      }.merge(params)
    end

    def self.test_transfer_array
      {
        :data => [test_transfer, test_transfer, test_transfer],
        :object => 'list',
        :url => '/v1/transfers'
      }
    end

    def self.test_invalid_api_key_error
      {
        "error" => {
          "type" => "invalid_request_error",
          "message" => "Invalid API Key provided: invalid"
        }
      }
    end

    def self.test_invalid_exp_year_error
      {
        "error" => {
          "code" => "invalid_expiry_year",
          "param" => "exp_year",
          "type" => "card_error",
          "message" => "Your card's expiration year is invalid"
        }
      }
    end

    def self.test_missing_id_error
      {
        :error => {
          :param => "id",
          :type => "invalid_request_error",
          :message => "Missing id"
        }
      }
    end

    def self.test_delete_subscription(params={})
      {
        deleted: true
      }.merge(params)
    end

    def self.test_api_error
      {
        :error => {
          :type => "api_error"
        }
      }
    end

    def self.test_delete_discount_response
      {
        :deleted => true,
        :id => "di_test_coupon"
      }
    end

  end
end
