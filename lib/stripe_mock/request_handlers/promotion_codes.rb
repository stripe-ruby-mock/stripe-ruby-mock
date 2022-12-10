module StripeMock
  module RequestHandlers
    module PromotionCodes

      def PromotionCodes.included(klass)
        klass.add_handler 'post /v1/promotion_codes',       :new_promotion_code
        klass.add_handler 'post /v1/promotion_codes/(.*)',  :update_promotion_code
        klass.add_handler 'get /v1/promotion_codes/(.*)',   :get_promotion_code
        klass.add_handler 'get /v1/promotion_codes',        :list_promotion_codes
      end

      def new_promotion_code(route, method_url, params, headers)
        params[:id] ||= new_id('promo')
        raise Stripe::InvalidRequestError.new('Missing required param: coupon', 'promotion_code', http_status: 400) unless params[:coupon]

        coupon = params[:coupon]
        coupon_id = coupon.is_a?(Stripe::Coupon) ? coupon[:id] : coupon.to_s
        coupon = assert_existence :coupon, coupon_id, coupons[coupon_id]

        promotion_code = Data.mock_promotion_code(params)

        add_coupon_to_object(promotion_code, coupon)

        promotion_codes[params[:id]] = promotion_code
      end

      def get_promotion_code(route, method_url, params, headers)
        route =~ method_url
        assert_existence :promotion_code, $1, promotion_codes[$1]
      end

      def update_promotion_code(route, method_url, params, headers)
        route =~ method_url
        assert_existence :promotion_code, $1, promotion_codes[$1]
        promotion_codes[$1].merge!(params)
      end

      def list_promotion_codes(route, method_url, params, headers)
        Data.mock_list_object(promotion_codes.values, params)
      end
    end
  end
end
