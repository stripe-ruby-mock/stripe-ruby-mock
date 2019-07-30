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
        secret = new_id('secret')

        ensure_payment_intent_required_params(params)

        payment_intents[id] = Data.mock_payment_intent(
          params.merge(
            id: id,
            client_secret: "#{id}_#{secret}",
            status: status(params)
          )
        )

        confirm_intent(payment_intents[id]) if params[:confirm]
        payment_intents[id]
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

        confirm_intent(payment_intent)
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
        elsif params[:customer].nil?
          require_param(:customer)
        elsif non_integer_charge_amount?(params)
          raise Stripe::InvalidRequestError.new("Invalid integer: #{params[:amount]}", 'amount', http_status: 400)
        elsif non_positive_charge_amount?(params)
          raise Stripe::InvalidRequestError.new('Invalid positive integer', 'amount', http_status: 400)
        end
      end

      def confirm_intent(payment_intent)
        raise Stripe::InvalidRequestError.new("You cannot confirm this PaymentIntent because it's missing a payment method. To confirm the PaymentIntent with #{payment_intent[:customer]}, specify a payment method attached to this customer along with the customer ID.", '', http_status: 400) unless payment_intent[:payment_method]
        require_authentication_cards = [3220, 3155, 3184, 3178, 3055] # or fingerprint

        if payment_intent[:status] == 'requires_confirmation'
          unless require_authentication_cards.include?(payment_methods[payment_intent[:payment_method]][:card][:last4])
            charge = create_charge(payment_intent)

            payment_intent[:charges][:total_count] += 1
            payment_intent[:charges][:data] << charge
            payment_intent[:status] = 'succeeded'
          else
            payment_intent[:status] = 'requires_action' # check status for not enought founds
          end
        end

        payment_intent
      end

      def status(params)
        if params[:payment_method]
          return 'requires_confirmation' if payment_methods[params[:payment_method]]
          raise Stripe::InvalidRequestError.new("No such payment_method: #{params[:payment_method]}", '', http_status: 400)
        else
          'requires_payment_method'
        end
      end

      def create_charge(payment_intent)
        id = new_id('ch')
        charges[id] = Data.mock_charge(
          id: id,
          customer: payment_intent[:customer],
          amount: payment_intent[:amount],
          payment_method: payment_intent[:payment_method],
          payment_intent: payment_intent[:id],
          paid: true
        )
        charges[id]
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
