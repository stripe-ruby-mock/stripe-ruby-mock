module StripeMock
  module RequestHandlers
    module Helpers

      def get_customer_subscription(customer, sub_id)
        customer[:subscriptions][:data].find{|sub| sub[:id] == sub_id }
      end

      def add_subscription_to_customer(plan, cus, start_time = nil)
        start_time ||= Time.now.utc.to_i
        params = { id: new_id('su'), plan: plan, customer: cus[:id], current_period_start: start_time, current_period_end: get_ending_time(start_time, plan) }

        if plan[:trial_period_days].nil?
          params.merge!({status: 'active', trial_start: nil, trial_end: nil})
        else
          params.merge!({status: 'trialing', trial_start: Time.now.utc.to_i, trial_end: (Time.now.utc.to_i + plan[:trial_period_days]*86400) })
        end

        subscription = Data.mock_subscription params

        cus[:subscriptions] = Data.mock_subscriptions_array(url: "/v1/customers/#{cus[:id]}/subscriptions") unless cus[:subscriptions]
        cus[:subscriptions][:count] = (cus[:subscriptions][:count] ? cus[:subscriptions][:count]+1 : 1 )
        cus[:subscriptions][:data] << subscription
        subscription
      end

      # intervals variable is set to 1 when calculating current_period_end from current_period_start & plan
      # intervals variable is set to 2 when calculating Stripe::Invoice.upcoming end from current_period_start & plan
      def get_ending_time(start_time, plan, intervals = 1)
        case plan[:interval]
          when "week"
            start_time + (604800 * (plan[:interval_count] || 1) * intervals)
          when "month"
            (Time.at(start_time).to_datetime >> ((plan[:interval_count] || 1) * intervals)).to_time.to_i
          when "year"
            (Time.at(start_time).to_datetime >> (12 * intervals)).to_time.to_i # max period is 1 year
          else
            start_time
        end
      end

    end
  end
end
