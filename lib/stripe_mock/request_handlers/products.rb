module StripeMock
  module RequestHandlers
    module Products
      def self.included(base)
        base.add_handler 'post /v1/products',        :create_product
        base.add_handler 'get /v1/products/(.*)',    :retrieve_product
        base.add_handler 'post /v1/products/(.*)',   :update_product
        base.add_handler 'get /v1/products',         :list_products
        base.add_handler 'delete /v1/products/(.*)', :destroy_product
      end

      def create_product(_route, _method_url, params, _headers)
        params[:id] ||= new_id('prod')

        default_price_data_params = params.delete(:default_price_data)

        validate_create_product_params(params)
        products[params[:id]] = Data.mock_product(params)
        product = products[params[:id]]

        if default_price_data_params.is_a?(Hash)
          default_price_data_params.reject! { |k, _| %i[product product_data].include?(k) }
          default_price_data_params[:id] ||= new_id('price')
          default_price_data_params.merge!(product: product[:id])
          validate_create_price_params(default_price_data_params)
          prices[default_price_data_params[:id]] = Data.mock_price(default_price_data_params)
          product[:default_price] = default_price_data_params[:id]
        end

        product
      end

      def retrieve_product(route, method_url, _params, _headers)
        id = method_url.match(route).captures.first
        assert_existence :product, id, products[id]
      end

      def update_product(route, method_url, params, _headers)
        id = method_url.match(route).captures.first
        product = assert_existence :product, id, products[id]

        product.merge!(params)
      end

      def list_products(_route, _method_url, params, _headers)
        limit = params[:limit] || 10
        products_list = products.values.take(limit)

        if params[:expand].is_a?(Array) && params[:expand].any? { |data| data.match?(/data.default_price/) }
          products_list.each do |product|
            next if product[:default_price].nil?

            product[:default_price] = prices[product[:default_price]]
          end
          params.delete(:expand)
        end

        Data.mock_list_object(products_list, params)
      end

      def destroy_product(route, method_url, _params, _headers)
        id = method_url.match(route).captures.first
        assert_existence :product, id, products[id]

        products.delete(id)
        { id: id, object: 'product', deleted: true }
      end
    end
  end
end
