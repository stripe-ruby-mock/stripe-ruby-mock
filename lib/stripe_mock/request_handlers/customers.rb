module StripeMock
  module RequestHandlers
    module Customers

      def Customers.included(klass)
        klass.add_handler 'post /v1/customers',                     :new_customer
        klass.add_handler 'post /v1/customers/(.*)/subscription',   :update_subscription
        klass.add_handler 'delete /v1/customers/(.*)/subscription', :cancel_subscription
        klass.add_handler 'post /v1/customers/(.*)',                :update_customer
        klass.add_handler 'get /v1/customers/(.*)',                 :get_customer
        klass.add_handler 'get /v1/customers',                      :list_customers
      end

      def new_customer(route, method_url, params, headers)
        params[:id] ||= new_id('cus')
        cards = []
        if params[:card]
          cards << get_card_by_token(params.delete(:card))
          params[:default_card] = cards.first[:id]
        end
        customers[ params[:id] ] = Data.test_customer(cards, params)
      end

      def update_subscription(route, method_url, params, headers)
        route =~ method_url

        customer = customers[$1]
        assert_existance :customer, $1, customer
        plan = plans[ params[:plan] ]
        assert_existance :plan, params[:plan], plan

        sub = Data.test_subscription id: new_id('su'), plan: plan, customer: $1
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

        Data.test_delete_subscription(id: sub[:id])
      end

      def update_customer(route, method_url, params, headers)
        route =~ method_url
        assert_existance :customer, $1, customers[$1]

        card_id = new_id('cc') if params.delete(:card)
        cus = customers[$1] ||= Data.test_customer([], :id => $1)
        cus.merge!(params)

        if card_id
          new_card = Data.test_card(id: card_id, customer: cus[:id])

          if cus[:cards][:count] == 0
            cus[:cards][:count] += 1
          else
            cus[:cards][:data].delete_if {|card| card[:id] == cus[:default_card]}
          end
          cus[:cards][:data] << new_card
          cus[:default_card] = new_card[:id]
        end

        cus
      end

      def get_customer(route, method_url, params, headers)
        route =~ method_url
        assert_existance :customer, $1, customers[$1]
        customers[$1] ||= Data.test_customer([], :id => $1)
      end

      def list_customers(route, method_url, params, headers)
        customers.values
      end

    end
  end
end
