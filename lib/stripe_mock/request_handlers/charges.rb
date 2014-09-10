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
      end

      def new_charge(route, method_url, params, headers)
        id = new_id('ch')

        if params[:card] && params[:card].is_a?(String)
          params[:card] = get_card_by_token(params[:card])
        elsif params[:card] && params[:card][:id]
          raise Stripe::InvalidRequestError.new("Invalid token id: #{params[:card]}", 'card', 400)
        end

        charges[id] = Data.mock_charge(params.merge :id => id, :balance_transaction => new_balance_transaction('txn'))
      end

      def get_charges(route, method_url, params, headers)
        params[:offset] ||= 0
        params[:count] ||= 10

        clone = charges.clone

        if params[:customer]
          clone.delete_if { |k,v| v[:customer] != params[:customer] }
        end

        clone.values[params[:offset], params[:count]]
      end

      def get_charge(route, method_url, params, headers)
        route =~ method_url
        assert_existance :charge, $1, charges[$1]
      end

      def capture_charge(route, method_url, params, headers)
        route =~ method_url
        charge = assert_existance :charge, $1, charges[$1]

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

    end
  end
end
