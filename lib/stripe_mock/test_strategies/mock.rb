module StripeMock
  module TestStrategies
    class Mock < Base

      def create_plan(params={})
        Stripe::Plan.create create_plan_params(params)
      end

      def delete_plan(plan_id)
        if StripeMock.state == 'remote'
          StripeMock.client.destroy_resource('plans', plan_id)
        elsif StripeMock.state == 'local'
          StripeMock.instance.plans.delete(plan_id)
        end
      end

      def renew_subscription(subscription_id)
puts "StripeMock.state=#{StripeMock.state}"
        if StripeMock.state == 'remote'
          StripeMock.client.renew_subscription(subscription_id)
        elsif StripeMock.state == 'local'
          subscription = assert_existence :subscription, subscription_id, StripeMock.instance.subscriptions[subscription_id]
          if subscription.present?
            subscription.renew_subscription
          else
            raise "Unable to renew subscription #{subscription_id} because this subscription does not exist"
          end
        end
      end

    end
  end
end
