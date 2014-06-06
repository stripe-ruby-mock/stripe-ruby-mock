module StripeMock
  module TestStrategies
    class Live < Base

      def create_plan(params)
        raise "get_or_create_plan requires an :id" if params[:id].nil?
        begin
          plan = Stripe::Plan.retrieve params[:id]
          plan.delete
        rescue Stripe::StripeError => e
          # Nothing; we just wanted to make sure this plan no longer exists
        end
        Stripe::Plan.create plan_params(params)
      end

    end
  end
end
