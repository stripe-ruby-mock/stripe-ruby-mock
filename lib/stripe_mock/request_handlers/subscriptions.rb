module StripeMock
  module RequestHandlers
    module Subscriptions

      def Subscriptions.included(klass)
        klass.add_handler 'get /v1/subscriptions', :retrieve_subscriptions
        klass.add_handler 'post /v1/subscriptions', :create_subscription
        klass.add_handler 'get /v1/subscriptions/(.*)', :retrieve_subscription
        klass.add_handler 'post /v1/subscriptions/(.*)', :update_subscription
        klass.add_handler 'delete /v1/subscriptions/(.*)', :cancel_subscription

        klass.add_handler 'post /v1/customers/(.*)/subscription(?:s)?', :create_customer_subscription
        klass.add_handler 'get /v1/customers/(.*)/subscription(?:s)?/(.*)', :retrieve_customer_subscription
        klass.add_handler 'get /v1/customers/(.*)/subscription(?:s)?', :retrieve_customer_subscriptions
        klass.add_handler 'post /v1/customers/(.*)subscription(?:s)?/(.*)', :update_subscription
        klass.add_handler 'delete /v1/customers/(.*)/subscription(?:s)?/(.*)', :cancel_subscription
      end

      def retrieve_customer_subscription(route, method_url, params, headers)
        route =~ method_url

        customer = assert_existence :customer, $1, customers[$1]
        subscription = get_customer_subscription(customer, $2)

        assert_existence :subscription, $2, subscription
      end

      def retrieve_customer_subscriptions(route, method_url, params, headers)
        route =~ method_url

        customer = assert_existence :customer, $1, customers[$1]
        customer[:subscriptions]
      end

      def create_customer_subscription(route, method_url, params, headers)
        route =~ method_url

        subscription_plans = get_subscription_plans_from_params(params)
        customer = assert_existence :customer, $1, customers[$1]

        if params[:source]
          new_card = get_card_by_token(params.delete(:source))
          add_card_to_object(:customer, new_card, customer)
          customer[:default_source] = new_card[:id]
        end

        subscription = Data.mock_subscription({ id: (params[:id] || new_id('su')) })
        subscription = resolve_subscription_changes(subscription, subscription_plans, customer, params)

        # Ensure customer has card to charge if plan has no trial and is not free
        # Note: needs updating for subscriptions with multiple plans
        verify_card_present(customer, subscription_plans.first, subscription, params)

        if params[:coupon]
          coupon_id = params[:coupon]

          # assert_existence returns 404 error code but Stripe returns 400
          # coupon = assert_existence :coupon, coupon_id, coupons[coupon_id]

          coupon = coupons[coupon_id]

          if coupon
            subscription[:discount] = Stripe::Util.convert_to_stripe_object({ coupon: coupon }, {})
          else
            raise Stripe::InvalidRequestError.new("No such coupon: #{coupon_id}", 'coupon', http_status: 400)
          end
        end

        subscriptions[subscription[:id]] = subscription
        add_subscription_to_customer(customer, subscription)

        subscriptions[subscription[:id]]
      end

      def create_subscription(route, method_url, params, headers)
        route =~ method_url

        subscription_plans = get_subscription_plans_from_params(params)

        customer = params[:customer]
        customer_id = customer.is_a?(Stripe::Customer) ? customer[:id] : customer.to_s
        customer = assert_existence :customer, customer_id, customers[customer_id]

        if subscription_plans && customer
          subscription_plans.each do |plan|
            unless customer[:currency].to_s == plan[:currency].to_s
              raise Stripe::InvalidRequestError.new("Customer's currency of #{customer[:currency]} does not match plan's currency of #{plan[:currency]}", 'currency', http_status: 400)
            end
          end
        end

        if params[:source]
          new_card = get_card_by_token(params.delete(:source))
          add_card_to_object(:customer, new_card, customer)
          customer[:default_source] = new_card[:id]
        end

        allowed_params = %w(customer application_fee_percent coupon items metadata plan quantity source tax_percent trial_end trial_period_days current_period_start created prorate billing_cycle_anchor)
        unknown_params = params.keys - allowed_params.map(&:to_sym)
        if unknown_params.length > 0
          raise Stripe::InvalidRequestError.new("Received unknown parameter: #{unknown_params.join}", unknown_params.first.to_s, http_status: 400)
        end

        subscription = Data.mock_subscription({ id: (params[:id] || new_id('su')) })
        subscription = resolve_subscription_changes(subscription, subscription_plans, customer, params)

        # Ensure customer has card to charge if plan has no trial and is not free
        # Note: needs updating for subscriptions with multiple plans
        verify_card_present(customer, subscription_plans.first, subscription, params)

        if params[:coupon]
          coupon_id = params[:coupon]

          # assert_existence returns 404 error code but Stripe returns 400
          # coupon = assert_existence :coupon, coupon_id, coupons[coupon_id]

          coupon = coupons[coupon_id]

          if coupon
            subscription[:discount] = Stripe::Util.convert_to_stripe_object({ coupon: coupon }, {})
          else
            raise Stripe::InvalidRequestError.new("No such coupon: #{coupon_id}", 'coupon', http_status: 400)
          end
        end

        subscriptions[subscription[:id]] = subscription
        add_subscription_to_customer(customer, subscription)

        subscriptions[subscription[:id]]
      end

      def retrieve_subscription(route, method_url, params, headers)
        route =~ method_url

        assert_existence :subscription, $1, subscriptions[$1]
      end

      def retrieve_subscriptions(route, method_url, params, headers)
        route =~ method_url

        Data.mock_list_object(subscriptions.values, params)
        #customer = assert_existence :customer, $1, customers[$1]
        #customer[:subscriptions]
      end

      def update_subscription(route, method_url, params, headers)
        route =~ method_url

        subscription_id = $2 ? $2 : $1
        subscription = assert_existence :subscription, subscription_id, subscriptions[subscription_id]
        verify_active_status(subscription)

        customer_id = subscription[:customer]
        customer = assert_existence :customer, customer_id, customers[customer_id]

        if params[:source]
          new_card = get_card_by_token(params.delete(:source))
          add_card_to_object(:customer, new_card, customer)
          customer[:default_source] = new_card[:id]
        end

        subscription_plans = get_subscription_plans_from_params(params)

        # subscription plans are not being updated but load them for the response
        if subscription_plans.empty?
          subscription_plans = subscription[:items][:data].map { |item| item[:plan] }
        end

        if params[:coupon]
          coupon_id = params[:coupon]

          # assert_existence returns 404 error code but Stripe returns 400
          # coupon = assert_existence :coupon, coupon_id, coupons[coupon_id]

          coupon = coupons[coupon_id]
          if coupon
            subscription[:discount] = Stripe::Util.convert_to_stripe_object({ coupon: coupon }, {})
          elsif coupon_id == ""
            subscription[:discount] = Stripe::Util.convert_to_stripe_object(nil, {})
          else
            raise Stripe::InvalidRequestError.new("No such coupon: #{coupon_id}", 'coupon', http_status: 400)
          end
        end
        verify_card_present(customer, subscription_plans.first, subscription)

        if params[:cancel_at_period_end]
          subscription[:cancel_at_period_end] = true
          subscription[:canceled_at] = Time.now.utc.to_i
        elsif params.has_key?(:cancel_at_period_end)
          subscription[:cancel_at_period_end] = false
          subscription[:canceled_at] = nil
        end

        params[:current_period_start] = subscription[:current_period_start]
        subscription = resolve_subscription_changes(subscription, subscription_plans, customer, params)

        # delete the old subscription, replace with the new subscription
        customer[:subscriptions][:data].reject! { |sub| sub[:id] == subscription[:id] }
        customer[:subscriptions][:data] << subscription

        subscription
      end

      def cancel_subscription(route, method_url, params, headers)
        route =~ method_url

        subscription_id = $2 ? $2 : $1
        subscription = assert_existence :subscription, subscription_id, subscriptions[subscription_id]

        customer_id = subscription[:customer]
        customer = assert_existence :customer, customer_id, customers[customer_id]

        cancel_params = { canceled_at: Time.now.utc.to_i }
        cancelled_at_period_end = (params[:at_period_end] == true)
        if cancelled_at_period_end
          cancel_params[:cancel_at_period_end] = true
        else
          cancel_params[:status] = 'canceled'
          cancel_params[:cancel_at_period_end] = false
          cancel_params[:ended_at] = Time.now.utc.to_i
        end

        subscription.merge!(cancel_params)

        unless cancelled_at_period_end
          delete_subscription_from_customer customer, subscription
        end

        subscription
      end

      private

      def get_subscription_plans_from_params(params)
        plan_ids = if params[:plan]
                     [params[:plan].to_s]
                   elsif params[:items]
                     items = params[:items]
                     items = items.values if items.respond_to?(:values)
                     items.map { |item| item[:plan].to_s if item[:plan] }
                   else
                     []
                   end
        plan_ids.each do |plan_id|
          assert_existence :plan, plan_id, plans[plan_id]
        end
        plan_ids.map { |plan_id| plans[plan_id] }
      end

      def verify_card_present(customer, plan, subscription, params={})
        if customer[:default_source].nil? && customer[:trial_end].nil? &&
          (plan.nil? ||
            ((plan[:trial_period_days] || 0) == 0 &&
              plan[:amount] != 0 &&
              plan[:trial_end].nil?)) &&
          params[:trial_end].nil? &&
          (subscription.nil? || subscription[:trial_end].nil? || subscription[:trial_end] == 'now')

          if subscription[:items]
            trial = subscription[:items][:data].none? do |item|
              plan = item[:plan]
              (plan[:trial_period_days].nil? || plan[:trial_period_days] == 0) &&
                (plan[:trial_end].nil? || plan[:trial_end] == 'now')
            end
            return if trial
          end

          raise Stripe::InvalidRequestError.new('You must supply a valid card xoxo', nil, http_status: 400)
        end
      end

      def verify_active_status(subscription)
        id, status = subscription.values_at(:id, :status)

        if status == 'canceled'
          message = "No such subscription: #{id}"
          raise Stripe::InvalidRequestError.new(message, 'subscription', http_status: 404)
        end
      end
    end
  end
end
