module StripeMock
  module RequestHandlers
    module Refunds

      def Refunds.included(klass)
        klass.add_handler 'post /v1/refunds',               :new_refund
        klass.add_handler 'get /v1/charges',                :get_refunds
        klass.add_handler 'get /v1/charges/(.*)',           :get_refund
        klass.add_handler 'post /v1/charges/(.*)',          :update_refund
      end

      def new_refund(route, method_url, params, headers)
        id = new_id('re')

        ensure_required_params(params)
        bal_trans_params = { amount: params[:amount], source: params[:charge] }

        balance_transaction_id = new_balance_transaction('txn', bal_trans_params)

        refunds[id] = Data.mock_refund(
          params.merge :id => id,
          :balance_transaction => balance_transaction_id,
          :charge => params[:charge]
        )

        if params[:expand] == ['balance_transaction']
          refunds[id][:balance_transaction] =
            balance_transactions[balance_transaction_id]
        end

        refunds[id]
      end

      def update_refund(route, method_url, params, headers)
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

      def get_refunds(route, method_url, params, headers)
        params[:offset] ||= 0
        params[:limit] ||= 10

        clone = charges.clone

        if params[:customer]
          clone.delete_if { |k,v| v[:customer] != params[:customer] }
        end

        Data.mock_list_object(clone.values, params)
      end

      def get_refund(route, method_url, params, headers)
        route =~ method_url
        charge_id = $1 || params[:charge]
        assert_existence :charge, charge_id, charges[charge_id]
      end

      private

      def ensure_required_params(params)
        if non_integer_charge_amount?(params)
          raise Stripe::InvalidRequestError.new("Invalid integer: #{params[:amount]}", 'amount', 400)
        elsif non_positive_charge_amount?(params)
          raise Stripe::InvalidRequestError.new('Invalid positive integer', 'amount', 400)
        elsif params[:charge].nil?
          raise Stripe::InvalidRequestError.new('Must provide the identifier of the charge to refund.', nil)
        end
      end

      def non_integer_charge_amount?(params)
        params[:amount] && !params[:amount].is_a?(Integer)
      end

      def non_positive_charge_amount?(params)
        params[:amount] && params[:amount] < 1
      end

      def allowed_params(params)
        allowed = [:charge, :amount, :metadata, :reason, :refund_application_fee, :reverse_transfer]

        allowed
      end
    end
  end
end
