module StripeMock
  module RequestHandlers
    module Invoices

      def Invoices.included(klass)
        klass.add_handler 'post /v1/invoices',               :new_invoice
        klass.add_handler 'get /v1/invoices/upcoming',       :upcoming_invoice
        klass.add_handler 'post /v1/invoices/create_preview', :create_preview_invoice
        klass.add_handler 'get /v1/invoices/(.*)/lines',     :get_invoice_line_items
        klass.add_handler 'get /v1/invoices/((?!search).*)', :get_invoice
        klass.add_handler 'get /v1/invoices/search',         :search_invoices
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

      SEARCH_FIELDS = ["currency", "customer", "number", "receipt_number", "subscription", "total"].freeze
      def search_invoices(route, method_url, params, headers)
        require_param(:query) unless params[:query]

        results = search_results(invoices.values, params[:query], fields: SEARCH_FIELDS, resource_name: "invoices")
        Data.mock_list_object(results, params)
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
        invoice = assert_existence :invoice, $1, invoices[$1]
        charge = invoice_charge(invoice)
        invoice.merge!(
          :paid => true,
          :status => "paid",
          :attempted => true,
          :charge => charge[:id],
          :amount_paid => invoice[:amount_due],
          :amount_remaining => 0
        )
      end

      def upcoming_invoice(route, method_url, params, headers = {})
        stripe_account = headers && headers[:stripe_account] || Stripe.api_key
        route =~ method_url
        raise Stripe::InvalidRequestError.new('Missing required param: customer if subscription is not provided', nil, http_status: 400) if params[:customer].nil? && params[:subscription].nil?
        raise Stripe::InvalidRequestError.new('When previewing changes to a subscription, you must specify either `subscription` or `subscription_items`', nil, http_status: 400) if !params[:subscription_proration_date].nil? && params[:subscription].nil? && params[:subscription_plan].nil?
        raise Stripe::InvalidRequestError.new('Cannot specify proration date without specifying a subscription', nil, http_status: 400) if !params[:subscription_proration_date].nil? && params[:subscription].nil?

        if params[:subscription] && params[:customer].nil?
          params[:customer] = subscriptions[params[:subscription]][:customer]
        end
        customer = customers[stripe_account][params[:customer]]
        assert_existence :customer, params[:customer], customer

        raise Stripe::InvalidRequestError.new("No upcoming invoices for customer: #{customer[:id]}", nil, http_status: 404) if customer[:subscriptions][:data].length == 0

        subscription =
          if params[:subscription]
            customer[:subscriptions][:data].select{|s|s[:id] == params[:subscription]}.first
          else
            customer[:subscriptions][:data].min_by { |sub| sub[:current_period_end] }
          end

        preview = preview_subscription_changes(
          customer, subscription,
          plan_id: params[:subscription_plan],
          quantity: params[:subscription_quantity],
          proration_date: params[:subscription_proration_date],
          trial_end: params[:subscription_trial_end]
        )
        preview_invoice(customer, preview)
      end

      def create_preview_invoice(route, method_url, params, headers = {})
        stripe_account = headers && headers[:stripe_account] || Stripe.api_key
        route =~ method_url

        if params[:subscription] && params[:customer].nil? && subscriptions[params[:subscription]]
          params[:customer] = subscriptions[params[:subscription]][:customer]
        end
        raise Stripe::InvalidRequestError.new('Missing required param: customer', nil, http_status: 400) if params[:customer].nil?

        customer = customers[stripe_account][params[:customer]]
        assert_existence :customer, params[:customer], customer

        subscription = nil
        if params[:subscription]
          subscription = customer[:subscriptions][:data].select{|s|s[:id] == params[:subscription]}.first
          raise Stripe::InvalidRequestError.new("No such subscription: #{params[:subscription]}", nil, http_status: 404) unless subscription
        elsif customer[:subscriptions][:data].length > 0
          subscription = customer[:subscriptions][:data].min_by { |sub| sub[:current_period_end] }
        end

        # subscription_items and subscription_proration_date are pre-basil
        # spellings, still accepted so existing callers keep working.
        details = params[:subscription_details] || {}
        items = details[:items] || params[:subscription_items]
        items = items.values if items.respond_to?(:values)
        item = items&.first

        preview =
          if subscription
            preview_subscription_changes(
              customer, subscription,
              plan_id: item && (item[:plan] || item[:price]),
              quantity: item && item[:quantity],
              proration_date: details[:proration_date] || params[:subscription_proration_date],
              trial_end: details[:trial_end]
            )
          else
            { lines: [], subscription: nil, date: Time.now.to_i, prorating: false }
          end

        Array(params[:invoice_items]).each do |invoice_item|
          preview[:lines] << Data.mock_line_item(
            id: new_id('ii'),
            amount: invoice_item[:amount] || 0,
            description: invoice_item[:description] || 'Invoice item',
            quantity: invoice_item[:quantity] || 1
          )
        end

        preview_invoice(customer, preview)
      end

      private

      def preview_subscription_changes(customer, subscription, plan_id: nil, quantity: nil, proration_date: nil, trial_end: nil)
        if proration_date && !((subscription[:current_period_start]..subscription[:current_period_end]) === proration_date)
          raise Stripe::InvalidRequestError.new('Cannot specify proration date outside of current subscription period', nil, http_status: 400)
        end

        plan_id ||= subscription[:plan][:id]
        quantity ||= subscription[:quantity]
        prorating = plan_id != subscription[:plan][:id] || quantity != subscription[:quantity]
        lines = []

        if prorating
          invoice_date = Time.now.to_i
          new_plan = assert_existence :plan, plan_id, plans[plan_id.to_s]
          preview_subscription = Data.mock_subscription
          preview_subscription = resolve_subscription_changes(preview_subscription, [new_plan], customer, { trial_end: trial_end })
          preview_subscription[:id] = subscription[:id]
          preview_subscription[:quantity] = quantity
          proration_date ||= Time.now

          period_start = subscription[:current_period_start]
          period_end = subscription[:current_period_end]
          plan_amount = subscription[:plan][:amount] || subscription[:plan][:unit_amount]

          lines << Data.mock_line_item(
            id: new_id('ii'),
            amount: -(plan_amount.to_f * subscription[:quantity] * (period_end - proration_date.to_i) / (period_end - period_start)).ceil,
            description: 'Unused time',
            plan: subscription[:plan],
            period: { start: proration_date.to_i, end: period_end },
            quantity: subscription[:quantity],
            proration: true
          )

          if new_plan[:interval] == subscription[:plan][:interval] && new_plan[:interval_count] == subscription[:plan][:interval_count] && trial_end.nil?
            lines << Data.mock_line_item(
              id: new_id('ii'),
              amount: new_plan[:amount] * quantity * (period_end - proration_date.to_i) / (period_end - period_start),
              description: 'Remaining time',
              plan: new_plan,
              period: { start: proration_date.to_i, end: period_end },
              quantity: quantity,
              proration: true
            )
          end
        else
          preview_subscription = subscription
          invoice_date = subscription[:current_period_end]
        end

        lines << get_mock_subscription_line_item(preview_subscription)
        { lines: lines, subscription: preview_subscription, date: invoice_date, prorating: prorating }
      end

      def preview_invoice(customer, preview)
        subscription = preview[:subscription]
        date = preview[:date]
        period_start = subscription && !preview[:prorating] ? subscription[:current_period_start] : date
        period_end = subscription && !preview[:prorating] ? subscription[:current_period_end] : date

        Data.mock_invoice(preview[:lines],
          id: new_id('in'),
          customer: customer[:id],
          discount: customer[:discount],
          created: date,
          starting_balance: customer[:account_balance],
          subscription: subscription && subscription[:id],
          period_start: period_start,
          period_end: period_end,
          next_payment_attempt: (subscription ? subscription[:current_period_end] : date) + 3600)
      end

      def get_mock_subscription_line_item(subscription)
        plan_amount = subscription[:plan][:amount] || subscription[:plan][:unit_amount]

        Data.mock_line_item(
          id: subscription[:id],
          type: "subscription",
          subscription: subscription[:id],
          subscription_item: subscription.dig(:items, :data, 0, :id),
          plan: subscription[:plan],
          amount: subscription[:status] == 'trialing' ? 0 : plan_amount * subscription[:quantity],
          discountable: true,
          quantity: subscription[:quantity],
          period: {
            start: subscription[:current_period_end],
            end: get_ending_time(subscription[:current_period_start], subscription[:plan], 2)
          })
      end

      ## charge the customer on the invoice, if one does not exist, create
      #anonymous charge
      def invoice_charge(invoice)
        begin
          new_charge(nil, nil, {customer: invoice[:customer]["id"], amount: invoice[:amount_due], currency: StripeMock.default_currency}, nil)
        rescue Stripe::InvalidRequestError
          new_charge(nil, nil, {source: generate_card_token, amount: invoice[:amount_due], currency: StripeMock.default_currency}, nil)
        end
      end

    end
  end
end
