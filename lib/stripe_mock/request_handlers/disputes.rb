module StripeMock
  module RequestHandlers
    module Disputes

      def Disputes.included(klass)
        klass.add_handler 'get /v1/disputes/(.*)',        :get_dispute
        klass.add_handler 'post /v1/disputes/(.*)',       :update_dispute
        klass.add_handler 'post /v1/disputes/(.*)/close'  :close_dispute
        klass.add_handler 'get /v1/disputes',             :get_all_disputes    
      end

      def get_dispute(route, method_url, params, headers)
      end

      def update_dispute(route, method_url, params, headers)
      end

      def close_dispute(route, method_url, params, headers)
      end

      def get_all_disputes(route, method_url, params, headers)
      end

    end
  end
end
