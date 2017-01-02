module StripeMock
  module TestStrategies
    class Live < Base

      def create_plan(params={})
        raise "create_plan requires an :id" if params[:id].nil?
        delete_plan(params[:id])
        account = params.has_key?(:stripe_account) ? {:stripe_account => params[:stripe_account]} : {}
        Stripe::Plan.create(create_plan_params(params), account)
      end

      def delete_plan(plan_id)
        begin
          plan = Stripe::Plan.retrieve(plan_id)
          plan.delete
        rescue Stripe::StripeError => e
          # Do nothing; we just want to make sure this plan ceases to exists
        end
      end

      def create_coupon(params={})
        delete_coupon create_coupon_params(params)[:id]
        super
      end

      def delete_coupon(id)
        begin
          coupon = Stripe::Coupon.retrieve(id)
          coupon.delete
        rescue Stripe::StripeError
          # do nothing
        end
      end

      def generate_subscription_renewal_invoice(subscription_id)
        raise "Renewing subscriptions in Live mode not supported"
      end

    end
  end
end
