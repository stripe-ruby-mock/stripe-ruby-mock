module StripeMock
  module RequestHandlers
    module Topups
      def Topups.included(klass)
        klass.add_handler 'post /v1/topups',         :create_topup
        klass.add_handler 'get /v1/topups/([^/]*)',  :get_topup
        klass.add_handler 'get /v1/topups',          :list_topups
      end


      def create_topup(route, method_url, params, headers)
        params[:id] ||= new_id('tu')
        assert_amount_valid(params)
        assert_currency_valid(params)
        topups[params[:id]] ||= Data.mock_topup(params)
      end

      def get_topup(route, method_url, params, headers)
        route =~ method_url
        assert_existence :topup, $1, topups[$1]
      end

      def list_topups(route, method_url, params, headers)
        Data.mock_list_object(topups.values, params)
      end

      private

      def assert_amount_valid(params)
        if !params[:amount].to_i.positive?
          raise Stripe::InvalidRequestError.new('Amount must be a positive integer', nil, http_status: 400)
        end
      end

      def assert_currency_valid(params)
        curr = params[:currency]
        if !StripeMock::RequestHandlers::ParamValidators::SUPPORTED_CURRENCIES.include?(params[:currency])
          raise Stripe::InvalidRequestError.new('Currency must be a three-letter ISO currency code, in lowercase', nil, http_status: 400)
        end
      end
    end
  end
end