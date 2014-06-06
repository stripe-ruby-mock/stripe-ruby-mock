module StripeMock
  module TestStrategies
    class Mock < Base

      def create_plan(params)
        raise "get_or_create_plan requires an :id" if params[:id].nil?
        Stripe::Plan.create plan_params(params)
      end

      def plan_params(params={})
        {
          :id => 'mock_stripe_mock_default_plan_id',
          :name => '[Mock] StripeMock Default Plan ID',
          :amount => 1337,
          :currency => 'usd',
          :interval => 'month'
        }.merge(params)
      end

    end
  end
end
