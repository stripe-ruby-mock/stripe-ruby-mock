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

      def generate_subscription_renewal_invoice(subscription_id)
        if StripeMock.state == 'remote'
          StripeMock.client.generate_subscription_renewal_invoice(subscription_id)
        elsif StripeMock.state == 'local'
          StripeMock.instance.generate_subscription_renewal_invoice(subscription_id)
        end
      end

    end
  end
end
