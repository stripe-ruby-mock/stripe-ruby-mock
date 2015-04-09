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
        klass.add_handler 'post /v1/charges/(.*)',          :update_charge
      end

      def new_charge(route, method_url, params, headers)
        id = new_id('ch')

        if params[:source] && params[:source].is_a?(String)
          # if a customer is provided, the card parameter is assumed to be the actual
          # card id, not a token. in this case we'll find the card in the customer
          # object and return that.
          if params[:customer]
            params[:source] = get_card(customers[params[:customer]], params[:source])
          else
            params[:source] = get_card_by_token(params[:source])
          end
        elsif params[:source] && params[:source][:id]
          raise Stripe::InvalidRequestError.new("Invalid token id: #{params[:card]}", 'card', 400)
        end

        ensure_required_params(params)

        charges[id] = Data.mock_charge(params.merge :id => id, :balance_transaction => new_balance_transaction('txn'))
      end

      def update_charge(route, method_url, params, headers)
        route =~ method_url
        id = $1

        charge = assert_existence :charge, id, charges[id]

        allowed = [:description, :metadata, :receipt_email, :fraud_details]
        disallowed = params.keys - allowed
        if disallowed.count > 0
          raise Stripe::InvalidRequestError.new("Received unknown parameters: #{disallowed.join(', ')}" , '', 400)
        end

        charges[id] = charge.merge(params)
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
        assert_existence :charge, $1, charges[$1]
      end

      def capture_charge(route, method_url, params, headers)
        route =~ method_url
        charge = assert_existence :charge, $1, charges[$1]

        if params[:amount]
          refund = Data.mock_refund(
            :balance_transaction => new_balance_transaction('txn'),
            :id => new_id('re'),
            :amount => charge[:amount] - params[:amount]
          )
          add_refund_to_charge(refund, charge)
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
    end
  end
end
