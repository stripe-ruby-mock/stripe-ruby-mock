module StripeMock
  module RequestHandlers
    module Invoices

      def Invoices.included(klass)
        klass.add_handler 'post /v1/invoices',               :new_invoice
        klass.add_handler 'get /v1/invoices/upcoming',       :upcoming_invoice
        klass.add_handler 'get /v1/invoices/(.*)/lines',     :get_invoice_line_items
        klass.add_handler 'get /v1/invoices/(.*)',           :get_invoice
        klass.add_handler 'get /v1/invoices',                :list_invoices
        klass.add_handler 'post /v1/invoices/(.*)/pay',      :pay_invoice
        klass.add_handler 'post /v1/invoices/(.*)',          :update_invoice
      end

      def new_invoice(route, method_url, params, headers)
        id = new_id('in')
        invoice_item = Data.mock_line_item()
        invoices[id] = Data.mock_invoice([invoice_item], params.merge(:id => id))
      end

      def update_invoice(route, method_url, params, headers)
        route =~ method_url
        params.delete(:lines) if params[:lines]
        assert_existence :invoice, $1, invoices[$1]
        invoices[$1].merge!(params)
      end

      def list_invoices(route, method_url, params, headers)
        params[:offset] ||= 0
        params[:limit] ||= 10

        result = invoices.clone

        if params[:customer]
          result.delete_if { |k,v| v[:customer] != params[:customer] }
        end

        Data.mock_list_object(result.values, params)
      end

      def get_invoice(route, method_url, params, headers)
        route =~ method_url
        assert_existence :invoice, $1, invoices[$1]
      end

      def get_invoice_line_items(route, method_url, params, headers)
        route =~ method_url
        assert_existence :invoice, $1, invoices[$1]
        invoices[$1][:lines]
      end

      def pay_invoice(route, method_url, params, headers)
        route =~ method_url
        assert_existence :invoice, $1, invoices[$1]

        invoice_attributes = {:paid => true, :attempted => true, :closed => true}
        invoice_amount = invoices[$1][:amount_due]

        charge_id = new_id('ch')
        charges[charge_id] = Data.mock_charge(:id => charge_id, :customer => invoices[$1][:customer], :amount => invoice_amount)
        invoice_attributes[:charge] = charge_id

        bal_trans_params = { amount: invoice_amount, source: charge_id }
        invoice_attributes[:balance_transaction] = new_balance_transaction('txn', bal_trans_params)

        if subscriptions.has_key?(invoices[$1][:subscription])
          application_fee_percent = subscriptions[invoices[$1]][:application_fee_percent]
          application_fee_percent = 0 if application_fee_percent.nil?
          if application_fee_percent != 0
            application_fee_amount = application_fee_percent * invoice_amount
            charges[id][:application_fee] = new_application_fee('fee',
                                                                amount: application_fee_amount,
                                                                balance_transaction: invoice_attributes[:balance_transaction],
                                                                charge: charge_id)
            invoice_attributes[:application_fee] = application_fee_amount
          end
        end
        invoices[$1].merge!(invoice_attributes)
      end

      def upcoming_invoice(route, method_url, params, headers)
        route =~ method_url
        raise Stripe::InvalidRequestError.new('Missing required param: customer', nil, 400) if params[:customer].nil?

        customer = customers[params[:customer]]
        assert_existence :customer, params[:customer], customer

        raise Stripe::InvalidRequestError.new("No upcoming invoices for customer: #{customer[:id]}", nil, 404) if customer[:subscriptions][:data].length == 0

        most_recent = customer[:subscriptions][:data].min_by { |sub| sub[:current_period_end] }
        invoice_item = get_mock_subscription_line_item(most_recent)

        id = new_id('in')
        invoices[id] = Data.mock_invoice([invoice_item],
          id: id,
          customer: customer[:id],
          subscription: most_recent[:id],
          period_start: most_recent[:current_period_start],
          period_end: most_recent[:current_period_end],
          next_payment_attempt: most_recent[:current_period_end] + 3600 )
      end

      private

      def get_mock_subscription_line_item(subscription)
        Data.mock_line_item(
          id: subscription[:id],
          type: "subscription",
          plan: subscription[:plan],
          amount: subscription[:plan][:amount],
          discountable: true,
          quantity: 1,
          period: {
            start: subscription[:current_period_end],
            end: get_ending_time(subscription[:current_period_start], subscription[:plan], 2)
          })
      end

    end
  end
end
