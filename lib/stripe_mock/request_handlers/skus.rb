module StripeMock
  module RequestHandlers
    module SKUs
      def SKUs.included(klass)
        klass.add_handler 'post /v1/skus',        :new_sku
        klass.add_handler 'post /v1/skus/(.*)',   :update_sku
        klass.add_handler 'get /v1/skus/(.*)',    :get_sku
        klass.add_handler 'delete /v1/skus/(.*)', :delete_sku
        klass.add_handler 'get /v1/skus',         :list_skus
      end

      def new_sku(route, method_url, params, headers)
        params[:id] ||= new_id('sku')
        validate_create_sku_params(params)
        skus[ params[:id] ] = Data.mock_sku(params)
      end

      def update_sku(route, method_url, params, headers)
        route =~ method_url
        assert_existence :sku, $1, skus[$1]
        skus[$1].merge!(params)
      end

      def get_sku(route, method_url, params, headers)
        route =~ method_url
        assert_existence :sku, $1, skus[$1]
      end

      def delete_sku(route, method_url, params, headers)
        route =~ method_url
        assert_existence :sku, $1, skus.delete($1)
      end

      def list_skus(route, method_url, params, headers)
        limit = params[:limit] ? params[:limit] : 10
        Data.mock_list_object(skus.values.first(limit), limit: limit)
      end
    end
  end
end
