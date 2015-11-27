module StripeMock
  module RequestHandlers
    module Skus

      def Skus.included(klass)
        klass.add_handler 'post /v1/skus',                     :new_sku
        klass.add_handler 'post /v1/skus/(.*)',                :update_sku
        klass.add_handler 'get /v1/skus/(.*)',                 :get_sku
        klass.add_handler 'get /v1/skus?(.*)',                 :list_skus
      end

      def new_sku(route, method_url, params, headers)
        params[:id] ||= new_id('sku')
        skus[ params[:id] ] = Data.mock_sku(params)

        product = assert_existence :product, params[:product], products[params[:product]]
        product[:skus][:data] ||= []
        product[:skus][:data] << skus[params[:id]]

        skus[ params[:id] ]
      end

      def update_sku(route, method_url, params, headers)
        route =~ method_url

        sku = assert_existence :sku, $1, skus[$1]
        sku.merge!(params)

        product = assert_existence :product, sku[:product], products[sku[:product]]
        product[:skus][:data].map! { |x| x[:id] == $1 ? x.merge!(params) : x }
        
        sku
      end

      def get_sku(route, method_url, params, headers)
        route =~ method_url
        
        sku = assert_existence :sku, $1, skus[$1]
        product = assert_existence :product, sku[:product], products[sku[:product]]
        
        sku
      end

      def list_skus(route, method_url, params, headers)
        route =~ method_url
        url_params = Stripe::Util.symbolize_names(CGI::parse(method_url.split('?').last))

        product = assert_existence :product, url_params[:product].first, products[url_params[:product].first]
        product[:skus]
      end
    end
  end
end
