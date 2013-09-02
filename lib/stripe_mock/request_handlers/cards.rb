module StripeMock
  module RequestHandlers
    module Cards

      def Cards.included(klass)
        klass.add_handler 'post /v1/customers/(.*)/cards',          :create_card
      end

      def create_card(route, method_url, params, headers)
        route =~ method_url

        customer = customers[$1]
        assert_existance :customer, $1, customer

        add_card_from_token(customer, params[:card])
      end



      private
      def card_from_params(attrs_or_token)
        if attrs_or_token.is_a? Hash
          attrs_or_token = generate_card_token(attrs_or_token)
        end
        get_card_by_token(attrs_or_token)
      end

      def add_card_from_token(cus, attrs_or_token)
        new_card = card_from_params(attrs_or_token)
        new_card[:customer] = cus[:id]

        if cus[:cards][:count] == 0
          cus[:cards][:count] += 1
        else
          cus[:cards][:data].delete_if {|card| card[:id] == cus[:default_card]}
        end

        cus[:cards][:data] << new_card

        new_card
      end
    end
  end
end
