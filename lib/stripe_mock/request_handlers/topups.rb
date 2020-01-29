module StripeMock
  module RequestHandlers
    module Topups
      def Topups.included(klass)
        klass.add_handler 'post /v1/topups',         :new_topup
        klass.add_handler 'get /v1/topups/([^/]*)',  :get_customer
        klass.add_handler 'get /v1/topups',       :list_customers
      end


      def new_topup(route, method_url, params, headers)
        params[:id] ||= new_id('tu')
        assert_amount_valid(params)
        assert_currency_valid(params)
        topups[params[:id]] ||= Data.mock_topup(params)
      end

      private

      def assert_amount_valid(params)
        if params[:amount].nil? || params[:amount].match(/\A\d+\Z/).nil?
          raise Stripe::InvalidRequestError.new('Amount must be a positive integer', nil, http_status: 400)
        end
      end

      def assert_currency_valid(params)
        curr = params[:currency]
        if curr.nil? || curr.match(/[[:lower:][:lower:][:lower:]]/).nil?
          raise Stripe::InvalidRequestError.new('Currency must be a three-letter ISO currency code, in lowercase', nil, http_status: 400)
        end
      end
    end
  end
end