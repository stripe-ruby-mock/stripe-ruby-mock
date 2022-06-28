module StripeMock
  module RequestHandlers
    module PromotionCodes

      def PromotionCodes.included(klass)
        klass.add_handler 'post /v1/promotion_codes',        :new_promotion_code
        klass.add_handler 'get /v1/promotion_codes/(.*)',    :get_promotion_code
        klass.add_handler 'delete /v1/promotion_codes/(.*)', :delete_promotion_code
        klass.add_handler 'get /v1/promotion_codes',         :list_promotion_codes
      end

      def new_promotion_code(route, method_url, params, headers)
        params[:id] ||= new_id('coupon')
        raise Stripe::InvalidRequestError.new('Missing required param: coupon', 'promotion_code', http_status: 400) unless params[:coupon]
        promotion_codes[ params[:id] ] = Data.mock_promotion_code.merge(params)
      end

      def get_promotion_code(route, method_url, params, headers)
        route =~ method_url
        assert_existence :promotion_code, $1, promotion_codes[$1]
      end

      def delete_promotion_code(route, method_url, params, headers)
        route =~ method_url
        assert_existence :promotion_code, $1, promotion_codes.delete($1)
      end

      def list_promotion_codes
        Data.mock_list_object(promotion_codes.values, params)
      end

    end
  end
end
