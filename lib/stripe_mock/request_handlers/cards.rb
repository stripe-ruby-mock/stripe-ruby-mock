module StripeMock
  module RequestHandlers
    module Cards

      def Cards.included(klass)
        klass.add_handler 'post /v1/customers/(.*)/cards', :create_card
        klass.add_handler 'get /v1/customers/(.*)/cards/(.*)', :retrieve_card
        klass.add_handler 'delete /v1/customers/(.*)/cards/(.*)', :delete_card
        klass.add_handler 'post /v1/customers/(.*)/cards/(.*)', :update_card
      end

      def create_card(route, method_url, params, headers)
        route =~ method_url

        customer = customers[$1]
        assert_existance :customer, $1, customer

        card = card_from_params(params[:card])
        add_card_to_customer(card, customer)
      end

      def retrieve_card(route, method_url, params, headers)
        route =~ method_url

        customer = customers[$1]
        assert_existance :customer, $1, customer
        card = get_customer_card(customer, $2)
        assert_existance :card, $2, card
        card
      end

      def delete_card(route, method_url, params, headers)
        route =~ method_url

        customer = customers[$1]
        assert_existance :customer, $1, customer
        card = get_customer_card(customer, $2)
        assert_existance :card, $2, card
        card = { id: $2, deleted: true }
        customer[:cards][:data].reject!{|cc| 
          cc[:id] == card[:id]
        }
        card
      end

      def update_card(route, method_url, params, headers)
        route =~ method_url

        customer = customers[$1]
        assert_existance :customer, $1, customer
        card = get_customer_card(customer, $2)
        assert_existance :card, $2, card
        card.merge!(params)
        card
      end

      private

      def validate_card(card)
        [:exp_month, :exp_year].each do |field|
          card[field] = card[field].to_i
        end
        card
      end

      def card_from_params(attrs_or_token)
        if attrs_or_token.is_a? Hash
          attrs_or_token = generate_card_token(attrs_or_token)
        end
        card = get_card_by_token(attrs_or_token)
        validate_card(card)
      end
    end
  end
end
