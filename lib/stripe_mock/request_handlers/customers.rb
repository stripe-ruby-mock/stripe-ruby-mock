module StripeMock
  module RequestHandlers
    module Customers

      def Customers.included(klass)
        klass.add_handler 'post /v1/customers',                     :new_customer
        klass.add_handler 'post /v1/customers/(.*)/subscription',   :new_subscription
        klass.add_handler 'delete /v1/customers/(.*)/subscription', :cancel_subscription
        klass.add_handler 'post /v1/customers/(.*)',                :update_customer
        klass.add_handler 'get /v1/customers/(.*)',                 :get_customer
      end

      def new_customer(route, method_url, params, headers)
        id = new_id
        customers[id] = Data.test_customer(params.merge :id => id)
      end

      def new_subscription(route, method_url, params, headers)
        Data.test_subscription(params[:plan])
      end

      def cancel_subscription(route, method_url, params, headers)
        Data.test_delete_subscription(params[:id])
      end

      def update_customer(route, method_url, params, headers)
        route =~ method_url
        customers[$1] ||= Data.test_customer(:id => $1)
        customers[$1].merge!(params)
      end

      def get_customer(route, method_url, params, headers)
        route =~ method_url
        customers[$1] ||= Data.test_customer(:id => $1)
      end

    end
  end
end
