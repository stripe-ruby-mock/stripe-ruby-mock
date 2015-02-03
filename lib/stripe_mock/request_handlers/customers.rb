module StripeMock
  module RequestHandlers
    module Customers

      def Customers.included(klass)
        klass.add_handler 'post /v1/customers',                     :new_customer
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

        customers[ params[:id] ] = Data.mock_customer(cards, params)

        if params[:plan]
          plan_id = params[:plan].to_s
          plan = assert_existence :plan, plan_id, plans[plan_id]

          if params[:default_card].nil? && plan[:trial_period_days].nil? && plan[:amount] != 0
            raise Stripe::InvalidRequestError.new('You must supply a valid card', nil, 400)
          end

          subscription = Data.mock_subscription({ id: new_id('su') })
          subscription.merge!(custom_subscription_params(plan, customers[ params[:id] ], params))
          add_subscription_to_customer(customers[ params[:id] ], subscription)
        elsif params[:trial_end]
          raise Stripe::InvalidRequestError.new('Received unknown parameter: trial_end', nil, 400)
        end

        customers[ params[:id] ]
      end

      def update_customer(route, method_url, params, headers)
        route =~ method_url
        cus = assert_existence :customer, $1, customers[$1]
        cus.merge!(params)

        if params[:card]
          new_card = get_card_by_token(params.delete(:card))
          add_card_to_object(:customer, new_card, cus, true)
          cus[:default_card] = new_card[:id]
        end

        cus
      end

      def delete_customer(route, method_url, params, headers)
        route =~ method_url
        assert_existence :customer, $1, customers[$1]

        customers[$1] = {
          id: customers[$1][:id],
          deleted: true
        }
      end

      def get_customer(route, method_url, params, headers)
        route =~ method_url
        assert_existence :customer, $1, customers[$1]
      end

      def list_customers(route, method_url, params, headers)
        Data.mock_list_object(customers.values, params)
      end

    end
  end
end
