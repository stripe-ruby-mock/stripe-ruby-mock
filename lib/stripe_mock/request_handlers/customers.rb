module StripeMock
  module RequestHandlers
    module Customers

      def Customers.included(klass)
        klass.add_handler 'post /v1/customers',                     :new_customer
        klass.add_handler 'post /v1/customers/(.*)/subscription',   :update_subscription
        klass.add_handler 'delete /v1/customers/(.*)/subscription', :cancel_subscription
        klass.add_handler 'post /v1/customers/(.*)',                :update_customer
        klass.add_handler 'get /v1/customers/(.*)',                 :get_customer
        klass.add_handler 'delete /v1/customers/(.*)',              :delete_customer
        klass.add_handler 'get /v1/customers',                      :list_customers
      end

      def new_customer(route, method_url, params, headers)
        params[:id] ||= new_id('cus')
        cards = []
        if params[:card]
          cards << get_card_by_token(params.delete(:card))
          params[:default_card] = cards.first[:id]
        end

        if params[:plan]
          plan = plans[ params[:plan] ]
          assert_existance :plan, params[:plan], plan

          if params[:default_card].nil? && plan[:trial_period_days].nil? && plan[:amount] != 0
            raise Stripe::InvalidRequestError.new('You must supply a valid card', nil, 400)
          end

          sub = Data.mock_subscription id: new_id('su'), plan: plan, customer: params[:id]
          params[:subscription] = sub
        end

        customers[ params[:id] ] = Data.mock_customer(cards, params)
      end

      def update_subscription(route, method_url, params, headers)
        route =~ method_url

        customer = customers[$1]
        assert_existance :customer, $1, customer

        plan = plans[ params[:plan] ]
        assert_existance :plan, params[:plan], plan

        if params[:card]
          new_card = get_card_by_token(params.delete(:card))
          add_card_to_customer(new_card, customer)
          customer[:default_card] = new_card[:id]
        end

        # Ensure customer has card to charge if plan has no trial and is not free
        if customer[:default_card].nil? && plan[:trial_period_days].nil? && plan[:amount] != 0
          raise Stripe::InvalidRequestError.new('You must supply a valid card', nil, 400)
        end

        sub = Data.mock_subscription id: new_id('su'), plan: plan, customer: $1
        customer[:subscription] = sub
      end

      def cancel_subscription(route, method_url, params, headers)
        route =~ method_url

        customer = customers[$1]
        assert_existance :customer, $1, customer

        sub = customer[:subscription]
        assert_existance nil, nil, sub, "No active subscription for customer: #{$1}"

        plan = plans[ sub[:plan][:id] ]
        assert_existance :plan, params[:plan], plan

        if params[:at_period_end] == true
          status = 'active'
          cancel_at_period_end = true
        else
          status = 'canceled'
          cancel_at_period_end = false
        end

        sub = Data.mock_subscription id: sub[:id], plan: plan, customer: $1, status: status, cancel_at_period_end: cancel_at_period_end
        customer[:subscription] = sub
      end

      def update_customer(route, method_url, params, headers)
        route =~ method_url
        assert_existance :customer, $1, customers[$1]

        cus = customers[$1] ||= Data.mock_customer([], :id => $1)
        cus.merge!(params)

        if params[:card]
          new_card = get_card_by_token(params.delete(:card))
          add_card_to_customer(new_card, cus)
          cus[:default_card] = new_card[:id]
        end

        cus
      end

      def delete_customer(route, method_url, params, headers)
        route =~ method_url
        assert_existance :customer, $1, customers[$1]

        customers[$1] = {
          id: customers[$1][:id],
          deleted: true
        }

        customers[$1]
      end

      def get_customer(route, method_url, params, headers)
        route =~ method_url
        assert_existance :customer, $1, customers[$1]
        customers[$1] ||= Data.mock_customer([], :id => $1)
      end

      def list_customers(route, method_url, params, headers)
        customers.values
      end

    end
  end
end
