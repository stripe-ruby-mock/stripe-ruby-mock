module StripeMock
  module RequestHandlers
    module Charges

      def Charges.included(klass)
        klass.add_handler 'post /v1/charges',               :new_charge
        klass.add_handler 'get /v1/charges',                :get_charges
        klass.add_handler 'get /v1/charges/(.*)',           :get_charge
        klass.add_handler 'post /v1/charges/(.*)/capture',  :capture_charge
        klass.add_handler 'post /v1/charges/(.*)/refund',   :refund_charge
        klass.add_handler 'post /v1/charges/(.*)/refunds',  :create_refund
        klass.add_handler 'post /v1/refunds',               :create_refund
        klass.add_handler 'post /v1/charges/(.*)',          :update_charge
      end

      def new_charge(route, method_url, params, headers)
        if params[:idempotency_key] && charges.any?
          original_charge = charges.values.find { |c| c[:idempotency_key] == params[:idempotency_key]}
          return charges[original_charge[:id]] if original_charge
        end

        id = new_id('ch')

        if params[:source]
          if params[:source].is_a?(String)
            # if a customer is provided, the card parameter is assumed to be the actual
            # card id, not a token. in this case we'll find the card in the customer
            # object and return that.
            if params[:customer]
              params[:source] = get_card(customers[params[:customer]], params[:source])
            else
              params[:source] = get_card_by_token(params[:source])
            end
          elsif params[:source][:id]
            raise Stripe::InvalidRequestError.new("Invalid token id: #{params[:source]}", 'card', 400)
          end
        elsif params[:customer]
          customer = customers[params[:customer]]
          if customer && customer[:default_source]
            params[:source] = get_card(customer, customer[:default_source])
          end
        end

        ensure_required_params(params)
        if params[:capture] != false
           params[:balance_transaction] = new_balance_transaction('txn', { amount: params[:amount], source: id })
        end

        if headers[:stripe_account]
          params[:account] = headers[:stripe_account]
        end

        charges[id] = Data.mock_charge(params.merge :id => id)

        if params[:application_fee]
          if params[:capture] != false
            charges[id][:application_fee] = new_application_fee('fee', amount: params[:application_fee], charge: id, account: params[:account])
            application_fees[charges[id][:application_fee]][:balance_transaction] = new_balance_transaction('txn', {amount: params[:application_fee], source: charges[id][:application_fee], type: "application_fee", fee: 0})
          else
            # Stripe saves the application fee amount so that if the charge is later captured, the initial application fee amount is applied.  However, the
            # application_fee attribute of the Stripe charge is null so we need to save the amount for later.
            charges[id][:application_fee_amount] = params[:application_fee]
            charges[id][:application_fee] = nil
          end
        end
        charges[id]
      end

      def update_charge(route, method_url, params, headers)
        route =~ method_url
        id = $1

        charge = assert_existence :charge, id, charges[id]
        allowed = allowed_params(params)
        disallowed = params.keys - allowed
        if disallowed.count > 0
          raise Stripe::InvalidRequestError.new("Received unknown parameters: #{disallowed.join(', ')}" , '', 400)
        end

        charges[id] = Util.rmerge(charge, params)
      end

      def get_charges(route, method_url, params, headers)
        params[:offset] ||= 0
        params[:limit] ||= 10

        clone = charges.clone

        if params[:customer]
          clone.delete_if { |k,v| v[:customer] != params[:customer] }
        end

        Data.mock_list_object(clone.values, params)
      end

      def get_charge(route, method_url, params, headers)
        route =~ method_url
        charge_id = $1 || params[:charge]
        assert_existence :charge, charge_id, charges[charge_id]
      end

      def capture_charge(route, method_url, params, headers)
        route =~ method_url
        charge = assert_existence :charge, $1, charges[$1]

        if params[:amount]

          charge[:balance_transaction] = new_balance_transaction('txn', { amount: params[:amount], source: charge[:id] })

          refund = Data.mock_refund(
            :balance_transaction => new_balance_transaction('txn'),
            :id => new_id('re'),
            :amount => charge[:amount] - params[:amount]
          )
          add_refund_to_charge(refund, charge)
        end

        if params.has_key?(:application_fee) || charge.has_key?(:application_fee_amount)
          # When the charge is captured, the application fee amount originally specified when the charge was created will be collected unless
          # an updated application fee amount is supplied when the charge is captured.
          if params.has_key?(:application_fee)
            application_fee_amount = params[:application_fee]
          else
            application_fee_amount = charge[:application_fee_amount]
          end
          if application_fee_amount > 0
            charge[:application_fee] = new_application_fee('fee', amount: application_fee_amount, charge: charge[:id], account: charge[:account])
            application_fees[charge[:application_fee]][:balance_transaction] = new_balance_transaction('txn', {amount: application_fee_amount, source: charge[:application_fee], type: "application_fee", fee: 0})
          end
        end

        charge[:captured] = true
        charge
      end

      def refund_charge(route, method_url, params, headers)
        charge = get_charge(route, method_url, params, headers)

        refund = Data.mock_refund params.merge(
          :balance_transaction => new_balance_transaction('txn'),
          :id => new_id('re')
        )
        add_refund_to_charge(refund, charge)

        #TODO - need to refund application_fee if refund_application_fee parameter is true
        charge
      end

      def create_refund(route, method_url, params, headers)
        charge = get_charge(route, method_url, params, headers)

        refund = Data.mock_refund params.merge(
          :balance_transaction => new_balance_transaction('txn'),
          :id => new_id('re'),
          :charge => charge[:id]
        )
        add_refund_to_charge(refund, charge)

        #TODO - need to refund application_fee if refund_application_fee parameter is true
        refund
      end

      private

      def ensure_required_params(params)
        if params[:amount].nil?
          require_param(:amount)
        elsif params[:currency].nil?
          require_param(:currency)
        elsif non_integer_charge_amount?(params)
          raise Stripe::InvalidRequestError.new("Invalid integer: #{params[:amount]}", 'amount', 400)
        elsif non_positive_charge_amount?(params)
          raise Stripe::InvalidRequestError.new('Invalid positive integer', 'amount', 400)
        end
      end

      def non_integer_charge_amount?(params)
        params[:amount] && !params[:amount].is_a?(Integer)
      end

      def non_positive_charge_amount?(params)
        params[:amount] && params[:amount] < 1
      end

      def require_param(param)
        raise Stripe::InvalidRequestError.new("Missing required param: #{param}", param.to_s, 400)
      end

      def allowed_params(params)
        allowed = [:description, :metadata, :receipt_email, :fraud_details, :shipping]

        # This is a workaround for the way the Stripe API sends params even when they aren't modified.
        # Stipe will include those params even when they aren't modified.
        allowed << :fee_details if params.has_key?(:fee_details) && params[:fee_details].nil?
        allowed << :source if params.has_key?(:source) && params[:source].empty?
        if params.has_key?(:refunds) && (params[:refunds].empty? ||
           params[:refunds].has_key?(:data) && params[:refunds][:data].nil?)
          allowed << :refunds
        end

        allowed
      end
    end
  end
end
