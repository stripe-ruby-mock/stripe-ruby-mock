module StripeMock
  module RequestHandlers
    module Topups
      def Topups.included(klass)
        klass.add_handler 'post /v1/topups',                     :new_topup
        # klass.add_handler 'post /v1/customers/([^/]*)',             :update_customer
        # klass.add_handler 'get /v1/customers/([^/]*)',              :get_customer
        # klass.add_handler 'delete /v1/customers/([^/]*)',           :delete_customer
        # klass.add_handler 'get /v1/customers',                      :list_customers
        # klass.add_handler 'delete /v1/customers/([^/]*)/discount',  :delete_customer_discount
      end


      def new_topup(route, method_url, params, headers)
        params[:id] ||= new_id('tu')
        # route =~ method_url
        # assertion_on_praams to throw_errors
        topups[params[:id]] ||= Data.mock_topup(params)
      end
    end
  end
end