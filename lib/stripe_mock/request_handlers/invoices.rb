module StripeMock
  module RequestHandlers
    module Invoices

      def Invoices.included(klass)
        klass.add_handler 'post /v1/invoices',               :new_invoice
        klass.add_handler 'get /v1/invoices/upcoming',       :upcoming_invoice
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
        assert_existance :invoice, $1, invoices[$1]
        invoices[$1].merge!(params)
      end

      def list_invoices(route, method_url, params, headers)
        params[:offset] ||= 0
        params[:count] ||= 10

        result = invoices.clone

        if params[:customer]
          result.delete_if { |k,v| v[:customer] != params[:customer] }
        end

        result.values[params[:offset], params[:count]]
      end

      def get_invoice(route, method_url, params, headers)
        route =~ method_url
        assert_existance :invoice, $1, invoices[$1]
      end

      def pay_invoice(route, method_url, params, headers)
        route =~ method_url
        assert_existance :invoice, $1, invoices[$1]
        invoices[$1].merge!(:paid => true, :attempted => true, :charge => 'ch_1fD6uiR9FAA2zc')
      end

      def upcoming_invoice(route, method_url, params, headers)
        route =~ method_url
        raise Stripe::InvalidRequestError.new('Missing required param: customer', nil, 400) if params[:customer].nil?

        customer = customers[params[:customer]]
        assert_existance :customer, params[:customer], customer

        raise Stripe::InvalidRequestError.new("No upcoming invoices for customer: #{customer[:id]}", nil, 404) if customer[:subscriptions][:data].length == 0

        most_recent = customer[:subscriptions][:data].min_by { |sub| sub[:current_period_end] }
        invoice_item = get_mock_subscription_line_item(most_recent)

        Data.mock_invoice([invoice_item],
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
          quantity: 1,
          period: {
            start: subscription[:current_period_end],
            end: get_ending_time(subscription[:current_period_start], subscription[:plan], 2)
          })
      end

    end
  end
end
