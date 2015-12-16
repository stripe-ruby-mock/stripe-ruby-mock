module StripeMock
  module RequestHandlers
    module Disputes

      def Disputes.included(klass)
        klass.add_handler 'get /v1/disputes/(.*)',        :get_dispute
        klass.add_handler 'post /v1/disputes/(.*)',       :update_dispute
        klass.add_handler 'post /v1/disputes/(.*)/close', :close_dispute
        klass.add_handler 'get /v1/disputes',             :list_disputes    
      end

      def get_dispute(route, method_url, params, headers)
        route =~ method_url
        disputes[$1] = Data.mock_dispute(id: $1)
        assert_existence :dispute, $1, disputes[$1]
      end

      def update_dispute(route, method_url, params, headers)
      end

      def close_dispute(route, method_url, params, headers)
      end

      def list_disputes(route, method_url, params, headers)
        Data.mock_list_object(disputes.values, params)
      end

    end
  end
end
