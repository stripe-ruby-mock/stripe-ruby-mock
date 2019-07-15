module StripeMock
  module RequestHandlers
    module PaymentIntents
      ALLOWED_PARAMS = [:description, :metadata, :receipt_email, :shipping, :destination, :payment_method, :payment_method_types, :setup_future_usage, :transfer_data, :amount, :currency]

      def PaymentIntents.included(klass)
        klass.add_handler 'post /v1/payment_intents',               :new_payment_intent
        klass.add_handler 'get /v1/payment_intents',                :get_payment_intents
        klass.add_handler 'get /v1/payment_intents/(.*)',           :get_payment_intent
        klass.add_handler 'post /v1/payment_intents/(.*)/confirm',  :confirm_payment_intent
        klass.add_handler 'post /v1/payment_intents/(.*)/capture',  :capture_payment_intent
        klass.add_handler 'post /v1/payment_intents/(.*)/cancel',   :cancel_payment_intent
        klass.add_handler 'post /v1/payment_intents/(.*)',          :update_payment_intent
      end

      def new_payment_intent(route, method_url, params, headers)
        id = new_id('pi')

        ensure_payment_intent_required_params(params)
        payment_intents[id] = Data.mock_payment_intent(
          params.merge(
            id: id,
            status: params[:amount] == 3184 ? 'requires_action' : 'succeeded'
          )
        )

        payment_intents[id].clone
      end

      def update_payment_intent(route, method_url, params, headers)
        route =~ method_url
        id = $1

        payment_intent = assert_existence :payment_intent, id, payment_intents[id]
        payment_intents[id] = Util.rmerge(payment_intent, params.select{ |k,v| ALLOWED_PARAMS.include?(k)})
      end

      def get_payment_intents(route, method_url, params, headers)
        params[:offset] ||= 0
        params[:limit] ||= 10

        clone = payment_intents.clone

        if params[:customer]
          clone.delete_if { |k,v| v[:customer] != params[:customer] }
        end

        Data.mock_list_object(clone.values, params)
      end

      def get_payment_intent(route, method_url, params, headers)
        route =~ method_url
        payment_intent_id = $1 || params[:payment_intent]
        payment_intent = assert_existence :payment_intent, payment_intent_id, payment_intents[payment_intent_id]

        payment_intent = payment_intent.clone
        payment_intent
      end

      def capture_payment_intent(route, method_url, params, headers)
        route =~ method_url
        payment_intent = assert_existence :payment_intent, $1, payment_intents[$1]

        payment_intent[:status] = 'succeeded'
        payment_intent
      end

      def confirm_payment_intent(route, method_url, params, headers)
        route =~ method_url
        payment_intent = assert_existence :payment_intent, $1, payment_intents[$1]

        payment_intent[:status] = 'succeeded'
        payment_intent
      end

      def cancel_payment_intent(route, method_url, params, headers)
        route =~ method_url
        payment_intent = assert_existence :payment_intent, $1, payment_intents[$1]

        payment_intent[:status] = 'canceled'
        payment_intent
      end

      private

      def ensure_payment_intent_required_params(params)
        if params[:amount].nil?
          require_param(:amount)
        elsif params[:currency].nil?
          require_param(:currency)
        elsif non_integer_charge_amount?(params)
          raise Stripe::InvalidRequestError.new("Invalid integer: #{params[:amount]}", 'amount', http_status: 400)
        elsif non_positive_charge_amount?(params)
          raise Stripe::InvalidRequestError.new('Invalid positive integer', 'amount', http_status: 400)
        end
      end

      def non_integer_charge_amount?(params)
        params[:amount] && !params[:amount].is_a?(Integer)
      end

      def non_positive_charge_amount?(params)
        params[:amount] && params[:amount] < 1
      end
    end
  end
end
