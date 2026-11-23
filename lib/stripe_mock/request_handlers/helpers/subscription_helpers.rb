module StripeMock
  module RequestHandlers
    module Helpers

      def get_customer_subscription(customer, sub_id)
        customer[:subscriptions][:data].find{|sub| sub[:id] == sub_id }
      end

      def resolve_subscription_changes(subscription, plans, customer, options = {})
        subscription.merge!(custom_subscription_params(plans, customer, options))
        items = options[:items]
        items = items.values if items.respond_to?(:values)
        subscription[:items][:data] = plans.map do |plan|
          matching_item = items && items.detect { |item| [item[:price], item[:plan]].include? plan[:id] }
          if matching_item
            matching_item[:quantity] ||= 1
            matching_item[:id] ||= new_id('si')
            params = matching_item.merge(plan: plan)
            params[:price] = plan if plan[:object] == "price"
            Data.mock_subscription_item(params)
          else
            params = { plan: plan, id: new_id('si') }
            params[:price] = plan if plan[:object] == "price"
            Data.mock_subscription_item(params)
          end
        end
        subscription
      end

      def custom_subscription_params(plans, cus, options = {})
        verify_trial_end(options[:trial_end]) if options[:trial_end]

        plan = plans.first if plans.size == 1

        now = Time.now.utc.to_i
        created_time = options[:created] || now
        start_time = options[:current_period_start] || now
        params = { customer: cus[:id], current_period_start: start_time, created: created_time }
        params.merge!({ :plan => (plans.size == 1 ? plans.first : nil) })
        keys_to_merge = /application_fee_percent|quantity|metadata|tax_percent|billing|days_until_due|default_tax_rates|pending_invoice_item_interval|default_payment_method|collection_method/
        params.merge! options.select {|k,v| k =~ keys_to_merge}

        if options[:cancel_at_period_end] == true
          params.merge!(cancel_at_period_end: true, canceled_at: now)
        elsif options[:cancel_at_period_end] == false
          params.merge!(cancel_at_period_end: false, canceled_at: nil)
        end

        options.fetch(:cancellation_details, {}).each do |key, value|
          next if value.nil?

          if params[:cancel_at_period_end]
            params[:cancellation_details] ||= {}
            params[:cancellation_details][key] = value
          else
            raise Stripe::InvalidRequestError.new("`cancellation_details` can only be set on subscriptions that are set to cancel.", "cancellation_details", http_status: 400)
          end
        end

        # TODO: Implement coupon logic

        if (((plan && plan[:trial_period_days]) || 0) == 0 && options[:trial_end].nil?) || options[:trial_end] == "now"
          end_time = options[:billing_cycle_anchor] || get_ending_time(start_time, plan)
          params.merge!({status: 'active', current_period_end: end_time, trial_start: nil, trial_end: nil, billing_cycle_anchor: options[:billing_cycle_anchor] || created_time})
        else
          end_time = options[:trial_end] || (Time.now.utc.to_i + plan[:trial_period_days]*86400)
          params.merge!({status: 'trialing', current_period_end: end_time, trial_start: start_time, trial_end: end_time, billing_cycle_anchor: options[:billing_cycle_anchor] || created_time})
        end

        params
      end

      def add_subscription_to_customer(cus, sub)
        if sub[:trial_end].nil? || sub[:trial_end] == "now"
          id = new_id('ch')
          charges[id] = Data.mock_charge(
            :id => id,
            :customer => cus[:id],
            :amount => (sub[:plan] ? sub[:plan][:amount] : total_items_amount(sub[:items][:data]))
          )
        end

        if cus[:currency].nil?
          cus[:currency] = sub[:items][:data][0][:plan][:currency]
        elsif cus[:currency] != sub[:items][:data][0][:plan][:currency]
          raise Stripe::InvalidRequestError.new( "Can't combine currencies on a single customer. This customer has had a subscription, coupon, or invoice item with currency #{cus[:currency]}", 'currency', http_status: 400)
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
        return start_time unless plan

        interval = plan[:interval] || plan.dig(:recurring, :interval)
        interval_count = plan[:interval_count] || plan.dig(:recurring, :interval_count) || 1
        case interval
        when "week"
          start_time + (604800 * (interval_count) * intervals)
        when "month"
          (Time.at(start_time).to_datetime >> ((interval_count) * intervals)).to_time.to_i
        when "year"
          (Time.at(start_time).to_datetime >> (12 * intervals)).to_time.to_i # max period is 1 year
        else
          start_time
        end
      end

      # Brings a subscription up to date with the current time, the way Stripe's
      # billing cycle would once its current period ends (for example after moving
      # time forward in a test). A subscription set to cancel at period end is
      # canceled. Otherwise it renews for the next period and the customer is
      # charged; if there is no payment method to charge, it becomes past_due.
      def renew_subscription(subscription)
        now = Time.now.utc.to_i

        while %w[active trialing].include?(subscription[:status]) &&
              subscription[:current_period_end] && subscription[:current_period_end] <= now
          period_end = subscription[:current_period_end]

          if subscription[:cancel_at_period_end]
            subscription.merge!(status: 'canceled', ended_at: period_end)
            break
          end

          plan = subscription[:plan] || subscription.dig(:items, :data, 0, :plan)
          next_period_end = get_ending_time(period_end, plan)
          break if next_period_end <= period_end

          subscription.merge!(current_period_start: period_end, current_period_end: next_period_end)
          subscription[:status] = charge_subscription_renewal(subscription) ? 'active' : 'past_due'
        end

        subscription
      end

      def verify_trial_end(trial_end)
        if trial_end != "now"
          if !trial_end.is_a? Integer
            raise Stripe::InvalidRequestError.new('Invalid timestamp: must be an integer', nil, http_status: 400)
          elsif trial_end < Time.now.utc.to_i
            raise Stripe::InvalidRequestError.new('Invalid timestamp: must be an integer Unix timestamp in the future', nil, http_status: 400)
          elsif trial_end > Time.now.utc.to_i + 31557600*5 # five years
            raise Stripe::InvalidRequestError.new('Invalid timestamp: can be no more than five years in the future', nil, http_status: 400)
          end
        end
      end

      # Charges the customer for a renewed subscription period. Returns false when the
      # renewal requires a payment that can't be collected.
      def charge_subscription_renewal(subscription)
        amount = subscription[:plan] ? subscription[:plan][:amount] : total_items_amount(subscription[:items][:data])
        return true if amount.to_i.zero?
        return true if [subscription[:collection_method], subscription[:billing]].include?('send_invoice')

        customer = customers.values.map { |account_customers| account_customers[subscription[:customer]] }.compact.first
        return false unless subscription[:default_payment_method] ||
                            (customer && (customer[:default_source] || customer.dig(:invoice_settings, :default_payment_method)))

        id = new_id('ch')
        charges[id] = Data.mock_charge(id: id, customer: subscription[:customer], amount: amount)
        true
      end

      def total_items_amount(items)
        total = 0
        items.each do |item|
          quantity = item[:quantity] || 1
          amount = item[:plan][:unit_amount] || item[:plan][:amount]
          total += quantity * amount
        end
        total
      end

      def filter_by_timestamp(subscriptions, field:, value:)
        if value.is_a?(Hash)
          operator_mapping = { gt: :>, gte: :>=, lt: :<, lte: :<= }
          subscriptions.filter do |sub|
            sub[field].public_send(operator_mapping[value.keys[0]], value.values[0])
          end
        else
          subscriptions.filter do |sub|
            sub[field] == value
          end
        end
      end
    end
  end
end
