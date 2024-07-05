module StripeMock
  module RequestHandlers
    module SubscriptionSchedules

      def SubscriptionSchedules.included(klass)
        klass.add_handler 'get /v1/subscription_schedules/([^/]*)', :retrieve_subscription_schedules
        klass.add_handler 'post /v1/subscription_schedules/([^/]*)', :update_subscription_schedule
        klass.add_handler 'post /v1/subscription_schedules', :create_subscription_schedules
        klass.add_handler 'post /v1/subscription_schedules/([^/]*)/release', :release_subscription_schedule
      end

      def retrieve_subscription_schedules(route, method_url, params, headers)
        route =~ method_url

        assert_existence :subscription_schedule, $1, subscriptions_schedules[$1]
      end

      def create_subscription_schedules(route, method_url, params, headers)
        stripe_account = headers && headers[:stripe_account] || Stripe.api_key
        params[:id] ||= new_id('sch')

        if params[:from_subscription]
          subscription = params[:from_subscription]
          subscription_id = subscription.is_a?(Stripe::Subscription) ? subscription[:id] : subscription.to_s
          subscription = assert_existence :subscription, subscription_id, subscriptions[subscription_id]
        end

        subscriptions_schedules[params[:id]] = Data.mock_subscription_schedule(params)
        subscription[:schedule] = subscriptions_schedules[params[:id]]
        subscriptions_schedules[params[:id]]
      end

      def update_subscription_schedule(route, method_url, params, headers)
        route =~ method_url

        subscription_schedule = assert_existence :subscription_schedule, $1, subscriptions_schedules[$1]
        subscription_schedule.merge!(params)
      end

      def release_subscription_schedule(route, method_url, params, headers)
        route =~ method_url

        subscription_schedule = assert_existence :subscription_schedule, $1, subscriptions_schedules[$1]

        release_params = {
          status: 'released',
          released_at: Time.now.utc.to_i,
          released_subscription: subscription_schedule[:subscription]
        }

        subscription_schedule.merge!(release_params)
      end
    end
  end
end
