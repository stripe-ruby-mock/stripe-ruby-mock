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

      def plan_params(params={})
        {
          :id => 'live_stripe_mock_default_plan_id',
          :name => '[Live] StripeMock Default Plan ID',
          :amount => 1337,
          :currency => 'usd',
          :interval => 'month'
        }.merge(params)
      end

    end
  end
end
