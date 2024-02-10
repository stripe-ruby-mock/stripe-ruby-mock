module StripeMock
  module RequestHandlers
    module PromotionCodes

      def PromotionCodes.included(klass)
        klass.add_handler 'post /v1/promotion_codes',         :new_promotion_code
        klass.add_handler 'post /v1/promotion_codes/([^/]*)', :update_promotion_code
        klass.add_handler 'get /v1/promotion_codes/([^/]*)',  :get_promotion_code
        klass.add_handler 'get /v1/promotion_codes',          :list_promotion_code
      end

      def new_promotion_code(route, method_url, params, headers)
        params[:id] ||= new_id("promo")
        raise Stripe::InvalidRequestError.new("Missing required param: coupon", "promotion_code", http_status: 400) unless params[:coupon]

        if params[:restrictions]
          if params[:restrictions][:minimum_amount] && !params[:restrictions][:minimum_amount_currency]
            raise Stripe::InvalidRequestError.new(
              "You must pass minimum_amount_currency when passing minimum_amount", "minimum_amount_currency", http_status: 400
            )
          end
        end

        promotion_codes[ params[:id] ] = Data.mock_promotion_code(params)
      end

      def update_promotion_code(route, method_url, params, headers)
        route =~ method_url
        assert_existence :promotion_code, $1, promotion_codes[$1]
        promotion_codes[$1].merge!(params)
      end

      def get_promotion_code(route, method_url, params, headers)
        route =~ method_url
        assert_existence :promotion_code, $1, promotion_codes[$1]
      end

      def list_promotion_code(route, method_url, params, headers)
        Data.mock_list_object(promotion_codes.values, params)
      end
    end
  end
end
