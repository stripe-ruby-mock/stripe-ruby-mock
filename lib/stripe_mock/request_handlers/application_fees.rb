module StripeMock
  module RequestHandlers
    module ApplicationFees

      def ApplicationFees.included(klass)
        klass.add_handler 'get /v1/application_fees/(.*)',  :get_application_fee
        klass.add_handler 'get /v1/application_fees',       :list_application_fees
      end

      def get_application_fee(route, method_url, params, headers)
        route =~ method_url
        assert_existence :application_fee, $1, application_fees[$1]
      end

      def list_application_fees(route, method_url, params, headers)
        Data.mock_list_object(application_fees.values, params)
      end

    end
  end
end
