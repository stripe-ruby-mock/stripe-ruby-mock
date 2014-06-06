module StripeMock
  module TestStrategies
    class Mock < Base

      def create_plan(params)
        raise "get_or_create_plan requires an :id" if params[:id].nil?
        Stripe::Plan.create plan_params(params)
      end

    end
  end
end
