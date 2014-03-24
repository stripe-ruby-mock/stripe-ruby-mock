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

        params[:subscriptions] = Data.mock_subscriptions_array(url: "/v1/customers/#{params[:id]}/subscriptions")
        customers[ params[:id] ] = Data.mock_customer(cards, params)

        if params[:coupon]
          coupon = coupons[ params[:coupon] ]
          assert_existance :coupon, params[:coupon], coupon

          add_coupon_to_customer(customers[params[:id]], coupon)
        end

        if params[:plan]
          plan = plans[ params[:plan] ]
          assert_existance :plan, params[:plan], plan

          if params[:default_card].nil? && plan[:trial_period_days].nil? && plan[:amount] != 0
            raise Stripe::InvalidRequestError.new('You must supply a valid card', nil, 400)
          end

          add_subscription_to_customer(plan, customers[params[:id]] )
        end

        customers[ params[:id] ]
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

        if params[:coupon]
          coupon = coupons[ params[:coupon] ]
          assert_existance :coupon, params[:coupon], coupon

          add_coupon_to_customer(cus, coupon)
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
