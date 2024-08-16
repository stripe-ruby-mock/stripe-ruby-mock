module StripeMock
  module RequestHandlers
    module Prices

      def Prices.included(klass)
        klass.add_handler 'post /v1/prices',               :new_price
        klass.add_handler 'post /v1/prices/(.*)',          :update_price
        klass.add_handler 'get /v1/prices/((?!search).*)', :get_price
        klass.add_handler 'get /v1/prices/search',         :search_prices
        klass.add_handler 'get /v1/prices',                :list_prices
      end

      def new_price(route, method_url, params, headers)
        params[:id] ||= new_id('price')

        if params[:product_data]
          params[:product] = create_product(nil, nil, params[:product_data], nil)[:id] unless params[:product]
          params.delete(:product_data)
        end

        validate_create_price_params(params)
        prices[ params[:id] ] = Data.mock_price(params)
      end

      def update_price(route, method_url, params, headers)
        route =~ method_url
        assert_existence :price, $1, prices[$1]
        prices[$1].merge!(params)
      end

      def get_price(route, method_url, params, headers)
        route =~ method_url
        assert_existence :price, $1, prices[$1]
      end

      def list_prices(route, method_url, params, headers)
        limit = params[:limit] ? params[:limit] : 10
        price_data = prices.values
        validate_list_prices_params(params)

        if params.key?(:lookup_keys)
          price_data.select! do |price|
            params[:lookup_keys].include?(price[:lookup_key])
          end
        end

        if params.key?(:currency)
          price_data.select! do |price|
            params[:currency] == price[:currency]
          end
        end

        if params.key?(:product)
          price_data.select! do |price|
            params[:product] == price[:product]
          end
        end

        Data.mock_list_object(price_data.first(limit), params.merge!(limit: limit))
      end

      SEARCH_FIELDS = ["active", "currency", "lookup_key", "product", "type"].freeze
      def search_prices(route, method_url, params, headers)
        require_param(:query) unless params[:query]

        results = search_results(prices.values, params[:query], fields: SEARCH_FIELDS, resource_name: "prices")
        Data.mock_list_object(results, params)
      end
    end
  end
end
