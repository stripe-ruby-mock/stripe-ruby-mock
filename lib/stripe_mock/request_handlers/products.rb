module StripeMock
  module RequestHandlers
    module Products

      def Products.included(klass)
        klass.add_handler 'post /v1/products',                     :new_product
        klass.add_handler 'post /v1/products/(.*)',                :update_product
        klass.add_handler 'get /v1/products/(.*)',                 :get_product
        #klass.add_handler 'delete /v1/customers/(.*)',              :delete_customer
        #klass.add_handler 'get /v1/customers',                      :list_customers
      end

      def new_product(route, method_url, params, headers)
        params[:id] ||= new_id('prod')
        
        products[ params[:id] ] = Data.mock_product(params)

        products[ params[:id] ]
      end

      def get_product(route, method_url, params, headers)
        route =~ method_url

        assert_existence :product, $1, products[$1]
      end

      def update_product(route, method_url, params, headers)
        route =~ method_url
        
        prod = assert_existence :product, $1, products[$1]

        params.delete(:metadata) unless params[:metadata].present?
        # Delete those params if their value is nil. Workaround of the problematic way Stripe serialize objects
        empty_skus = (!params[:skus][:data].reject { |x| x.values.compact.any? }.any?) if params[:skus] && params[:skus][:data].is_a?(Array)
        params.delete(:skus) if params[:skus] && (params[:skus][:data].nil? || empty_skus)
        
        prod.merge!(params)
        prod
      end
    end
  end
end
