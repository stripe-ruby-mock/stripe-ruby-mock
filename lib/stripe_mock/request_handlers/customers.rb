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
        customers[ params[:id] ] = Data.test_customer(params)
      end

      def update_subscription(route, method_url, params, headers)
        route =~ method_url
        assert_existance :customer, $1, customers[$1]
        plan = plans[ params[:plan] ]
        assert_existance :plan, params[:plan], plan

        Data.test_subscription(plan: plan)
      end

      def cancel_subscription(route, method_url, params, headers)
        route =~ method_url
        assert_existance :customer, $1, customers[$1]
        Data.test_delete_subscription(params[:id])
      end

      def update_customer(route, method_url, params, headers)
        route =~ method_url
        assert_existance :customer, $1, customers[$1]
        customers[$1] ||= Data.test_customer(:id => $1)
        customers[$1].merge!(params)
      end

      def get_customer(route, method_url, params, headers)
        route =~ method_url
        assert_existance :customer, $1, customers[$1]
        customers[$1] ||= Data.test_customer(:id => $1)
      end

      def list_customers(route, method_url, params, headers)
        customers.values
      end

    end
  end
end
