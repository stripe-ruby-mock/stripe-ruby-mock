module StripeMock
  module RequestHandlers
    module Refunds

      def Refunds.included(klass)
        klass.add_handler 'get /v1/charges/(.*)/refunds', :retrieve_refunds
        klass.add_handler 'post /v1/charges/(.*)/refunds', :create_refund, '2014-06-17'
        klass.add_handler 'get /v1/charges/(.*)/refunds/(.*)', :retrieve_refund
        klass.add_handler 'post /v1/charges/(.*)/refunds/(.*)', :update_refund
      end

      def create_refund(route, method_url, params, headers)
        route =~ method_url

        charge = charges[$1]
        assert_existance :charge, $1, charge

        refund = Data.mock_refund_2014_06_17(params)
        add_refund_to_charge(refund, charge)
      end

      def retrieve_refunds(route, method_url, params, headers)
        # TODO
      end

      def retrieve_refund(route, method_url, params, headers)
        # TODO
      end

      def update_refund(route, method_url, params, headers)
        # TODO
      end
    end
  end
end
