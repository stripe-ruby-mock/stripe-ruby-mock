module StripeMock
  module RequestHandlers
    module Products

      def Products.included(klass)
        klass.add_handler 'post /v1/products',                     :new_product
        #klass.add_handler 'post /v1/customers/(.*)',                :update_customer
        #klass.add_handler 'get /v1/customers/(.*)',                 :get_customer
        #klass.add_handler 'delete /v1/customers/(.*)',              :delete_customer
        #klass.add_handler 'get /v1/customers',                      :list_customers
      end

      def new_product(route, method_url, params, headers)
        params[:id] ||= new_id('prod')
        
        products[ params[:id] ] = Data.mock_product(params)

        products[ params[:id] ]
      end
    end
  end
end
