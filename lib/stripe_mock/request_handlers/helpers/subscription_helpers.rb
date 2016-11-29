module StripeMock
  module RequestHandlers
    module Helpers

      def get_customer_subscription(customer, sub_id)
        customer[:subscriptions][:data].find{|sub| sub[:id] == sub_id }
      end

      def custom_subscription_params(plan, cus, options = {})
        verify_trial_end(options[:trial_end]) if options[:trial_end]

        start_time = options[:current_period_start] || Time.now.utc.to_i
        params = { plan: plan, customer: cus[:id], current_period_start: start_time }
        params.merge! options.select {|k,v| k =~ /application_fee_percent|quantity|metadata|tax_percent/}
        # TODO: Implement coupon logic

        if (plan[:trial_period_days].nil? && options[:trial_end].nil?) || options[:trial_end] == "now"
          end_time = get_ending_time(start_time, plan)
          params.merge!({status: 'active', current_period_end: end_time, trial_start: nil, trial_end: nil})
        else
          end_time = options[:trial_end] || (Time.now.utc.to_i + plan[:trial_period_days]*86400)
          params.merge!({status: 'trialing', current_period_end: end_time, trial_start: start_time, trial_end: end_time})
        end

        params
      end

      def add_subscription_to_customer(cus, sub)
        if sub[:trial_end].nil? || sub[:trial_end] == "now"
          id = new_id('ch')
          charges[id] = Data.mock_charge(:id => id, :customer => cus[:id], :amount => sub[:plan][:amount])
        end

        if cus[:currency].nil?
          cus[:currency] = sub[:plan][:currency]
        elsif cus[:currency] != sub[:plan][:currency]
          raise Stripe::InvalidRequestError.new( "Can't combine currencies on a single customer. This customer has had a subscription, coupon, or invoice item with currency #{cus[:currency]}", 'currency', 400)
        end
        cus[:subscriptions][:total_count] = (cus[:subscriptions][:total_count] || 0) + 1
        cus[:subscriptions][:data].unshift sub
      end

      def delete_subscription_from_customer(cus, subscription)
        cus[:subscriptions][:data].reject!{|sub|
          sub[:id] == subscription[:id]
        }
        cus[:subscriptions][:total_count] -=1
      end

      # `intervals` is set to 1 when calculating current_period_end from current_period_start & plan
      # `intervals` is set to 2 when calculating Stripe::Invoice.upcoming end from current_period_start & plan
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

      def verify_trial_end(trial_end)
        if trial_end != "now"
          if !trial_end.is_a? Integer
            raise Stripe::InvalidRequestError.new('Invalid timestamp: must be an integer', nil, 400)
          elsif trial_end < Time.now.utc.to_i
            raise Stripe::InvalidRequestError.new('Invalid timestamp: must be an integer Unix timestamp in the future', nil, 400)
          elsif trial_end > Time.now.utc.to_i + 31557600*5 # five years
            raise Stripe::InvalidRequestError.new('Invalid timestamp: can be no more than five years in the future', nil, 400)
          end
        end
      end

    end
  end
end
