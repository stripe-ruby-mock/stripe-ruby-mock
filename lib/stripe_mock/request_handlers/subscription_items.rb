module StripeMock
  module RequestHandlers
    module SubscriptionItems

      def SubscriptionItems.included(klass)
        klass.add_handler 'get /v1/subscription_items', :retrieve_subscription_items
        klass.add_handler 'post /v1/subscription_items', :create_subscription_items
      end

      def retrieve_subscription_items(route, method_url, params, headers)
        route =~ method_url
        Data.mock_list_object(subscriptions_items, params)
      end

      def create_subscription_items(route, method_url, params, headers)
        {}
      end
    end
  end
end
