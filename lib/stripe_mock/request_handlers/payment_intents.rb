module StripeMock
  module RequestHandlers
    module PaymentIntents
      ALLOWED_PARAMS = [:description, :metadata, :receipt_email, :shipping, :destination, :payment_method, :payment_method_types, :setup_future_usage, :transfer_data, :amount, :currency]

      def PaymentIntents.included(klass)
        klass.add_handler 'post /v1/payment_intents',               :new_payment_intent
        klass.add_handler 'get /v1/payment_intents',                :get_payment_intents
        klass.add_handler 'get /v1/payment_intents/((?!search).*)', :get_payment_intent
        klass.add_handler 'get /v1/payment_intents/search',         :search_payment_intents
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
            status: status(params),
          )
        )

        invoices[params[:invoice]][:payment_intent] = id if params[:invoice]
        confirm_intent(payment_intents[id]) if params[:confirm]

        payment_intents[id]
      end

      def update_payment_intent(route, method_url, params, headers)
        route =~ method_url
        payment_intent = assert_existence :payment_intent, $1, payment_intents[$1]
        if params[:payment_method]
          payment_intent[:payment_method] = params[:payment_method]
          payment_intent[:status] = 'requires_confirmation'
        end
        payment_intents[$1] = Util.rmerge(payment_intent, params.select{ |k,v| ALLOWED_PARAMS.include?(k)})
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

      SEARCH_FIELDS = ["amount", "currency", "customer", "status"].freeze
      def search_payment_intents(route, method_url, params, headers)
        require_param(:query) unless params[:query]

        results = search_results(payment_intents.values, params[:query], fields: SEARCH_FIELDS, resource_name: "payment_intents")
        Data.mock_list_object(results, params)
      end

      def capture_payment_intent(route, method_url, params, headers)
        route =~ method_url
        payment_intent = assert_existence :payment_intent, $1, payment_intents[$1]

        succeeded_payment_intent(payment_intent)
      end

      def confirm_payment_intent(route, method_url, params, headers)
        route =~ method_url
        payment_intent = assert_existence :payment_intent, $1, payment_intents[$1]

        if params[:payment_method]
          payment_intent[:payment_method] = params[:payment_method]
        end

        succeeded_payment_intent(payment_intent)
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
        require_authentication_cards = %w[3220 3155 3184 3178 3055]

        if payment_intent[:status] == 'requires_confirmation'
          unless require_authentication_cards.include?(get_card_last4(payment_intent))
            charge = create_charge(payment_intent)

            payment_intent[:charges][:total_count] += 1
            payment_intent[:charges][:data] << charge
            payment_intent[:status] = 'succeeded'
            invoices[payment_intent[:invoice]].merge!(paid: true, status: 'paid') if payment_intent[:invoice] && !invoices[payment_intent[:invoice]].nil?
          else
            payment_intent[:status] = 'requires_action' # check status for not enought founds
          end
        end

        payment_intent
      end

      def get_card_last4(payment_intent)
        payment_method = @payment_methods[payment_intent[:payment_method]]
        last4 = payment_method[:card][:last4] if payment_method.present?

        customer = @customers[Stripe.api_key][payment_intent[:customer]]
        last4 ||= customer[:sources][:data].last[:last4]
        if customer.present? && customer[:default_source]
          default_card = customer[:sources][:data].find {|source| source[:id] == customer[:default_source]}
          last4 = default_card[:last4] if default_card
        end

        last4
      end

      def status(params)
        customer = @customers[Stripe.api_key][params[:customer]]

        if params[:payment_method].blank? && customer.present? && customer[:default_source].blank?
          'requires_payment_method'
        else
          return 'requires_confirmation' if @payment_methods[params[:payment_method]] || (customer.present? && customer[:default_source])
          raise Stripe::InvalidRequestError.new("No such payment_method: #{params[:payment_method]}", '', http_status: 400)
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

      def succeeded_payment_intent(payment_intent)
        payment_intent[:status] = 'succeeded'
        btxn = new_balance_transaction('txn', { source: payment_intent[:id] })

        charge_id = new_id('ch')

        charges[charge_id] = Data.mock_charge(
          id: charge_id,
          balance_transaction: btxn,
          payment_intent: payment_intent[:id],
          amount: payment_intent[:amount],
          currency: payment_intent[:currency],
          payment_method: payment_intent[:payment_method]
        )

        payment_intent[:latest_charge] = charge_id

        payment_intent
      end
    end
  end
end
