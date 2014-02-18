module StripeMock
  module RequestHandlers
    module Subscriptions

      def Subscriptions.included(klass)
        klass.add_handler 'get /v1/customers/(.*)/subscriptions', :retrieve_subscriptions
        klass.add_handler 'post /v1/customers/(.*)/subscriptions', :create_subscription
        klass.add_handler 'get /v1/customers/(.*)/subscriptions/(.*)', :retrieve_subscription
        klass.add_handler 'post /v1/customers/(.*)/subscriptions/(.*)', :update_subscription
        klass.add_handler 'delete /v1/customers/(.*)/subscriptions/(.*)', :cancel_subscription
      end

      def create_subscription(route, method_url, params, headers)
        route =~ method_url

        customer = customers[$1]
        assert_existance :customer, $1, customer

        plan = plans[params[:plan]]
        assert_existance :plan, params[:plan], plan

        # Ensure customer has card to charge if plan has no trial and is not free
        verify_card_present(customer, plan)

        sub_params = { id: new_id('su'), plan: plan, customer: customer }
        if plan[:trial_period_days].nil?
          sub_params.merge!({status: 'active', trial_start: nil, trial_end: nil})
        else
          sub_params.merge!({status: 'trialing', trial_start: Time.now.to_i, trial_end: (Time.now + plan[:trial_period_days]).to_i })
        end

        subscription = Data.mock_subscription sub_params

        add_subscription_to_customer(subscription, customer)

        # oddly, subscription returned from 'create_subscription' does not expand plan
        subscription.merge(plan: params[:plan])
      end

      def retrieve_subscription(route, method_url, params, headers)
        route =~ method_url

        customer = customers[$1]
        assert_existance :customer, $1, customer
        subscription = get_customer_subscription(customer, $2)
        assert_existance :subscription, $2, subscription

        subscription
      end

      def retrieve_subscriptions(route, method_url, params, headers)
        route =~ method_url

        customer = customers[$1]
        assert_existance :customer, $1, customer

        subscription_list = Data.mock_subscriptions_array url: "/v1/customers/#{customer[:id]}/subscriptions", count: customer[:subscriptions][:data].length
        customer.subscriptions.each do |subscription|
          subscription_list[:data] << subscription
        end
        subscription_list
      end

      def update_subscription(route, method_url, params, headers)
        route =~ method_url

        customer = customers[$1]
        assert_existance :customer, $1, customer
        subscription = get_customer_subscription(customer, $2)
        assert_existance :subscription, $2, subscription

        if params[:card]
          new_card = get_card_by_token(params.delete(:card))
          add_card_to_customer(new_card, customer)
          customer[:default_card] = new_card[:id]
        end

        # expand the plan for addition to the customer object
        if params[:plan]
          plan_name = params[:plan]
          plan = plans[plan_name]
          assert_existance :plan, params[:plan], plan
          params[:plan] = plan
        end

        # Ensure customer has card to charge if plan has no trial and is not free
        verify_card_present(customer, plan)

        subscription.merge!(params)

        # delete the old subscription, replace with the new subscription
        customer[:subscriptions][:data].reject! { |sub| sub[:id] == subscription[:id] }
        customer[:subscriptions][:data] << subscription

        # oddly, subscription returned from 'create_subscription' does not expand plan
        subscription.merge(plan: plan_name)
      end

      def cancel_subscription(route, method_url, params, headers)
        route =~ method_url

        customer = customers[$1]
        assert_existance :customer, $1, customer
        subscription = get_customer_subscription(customer, $2)
        assert_existance :subscription, $2, subscription

        cancel_params = { canceled_at: Time.now.to_i }
        if params[:at_period_end] == true
          cancel_params[:cancel_at_period_end] = true
        else
          cancel_params[:status] = "canceled"
          cancel_params[:cancel_at_period_end] = false
          cancel_params[:ended_at] = Time.now.to_i
        end

        subscription.merge!(cancel_params)

        customer[:subscriptions][:data].reject!{|sub|
          sub[:id] == subscription[:id]
        }

        customer[:subscriptions][:data] << subscription
        subscription
      end

      private

      def verify_card_present(customer, plan)
        if customer[:default_card].nil? && plan[:trial_period_days].nil? && plan[:amount] != 0
          raise Stripe::InvalidRequestError.new('You must supply a valid card', nil, 400)
        end
      end

    end
  end
end