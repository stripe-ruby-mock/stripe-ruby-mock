module StripeMock
  module RequestHandlers
    module Cards

      def Cards.included(klass)
        klass.add_handler 'get /v1/customers/(.*)/cards', :retrieve_cards
        klass.add_handler 'post /v1/customers/(.*)/cards', :create_card
        klass.add_handler 'get /v1/customers/(.*)/cards/(.*)', :retrieve_card
        klass.add_handler 'delete /v1/customers/(.*)/cards/(.*)', :delete_card
        klass.add_handler 'post /v1/customers/(.*)/cards/(.*)', :update_card
        klass.add_handler 'get /v1/recipients/(.*)/cards/(.*)', :retrieve_recipient_card
        klass.add_handler 'post /v1/recipients/(.*)/cards', :create_recipient_card
        klass.add_handler 'delete /v1/recipients/(.*)/cards/(.*)', :delete_recipient_card
      end

      def create_card(route, method_url, params, headers)
        route =~ method_url
        add_card_to(:customer, $1, params, customers)
      end

      def create_recipient_card(route, method_url, params, headers)
        route =~ method_url
        add_card_to(:recipient, $1, params, recipients)
      end

      def retrieve_cards(route, method_url, params, headers)
        route =~ method_url
        customer = assert_existence :customer, $1, customers[$1]
        cards = customer[:cards]

        Data.mock_list_object(cards[:data])
      end

      def retrieve_card(route, method_url, params, headers)
        route =~ method_url
        customer = assert_existence :customer, $1, customers[$1]

        assert_existence :card, $2, get_card(customer, $2)
      end

      def retrieve_recipient_card(route, method_url, params, headers)
        route =~ method_url
        recipient = assert_existence :recipient, $1, recipients[$1]

        assert_existence :card, $2, get_card(recipient, $2, "Recipient")
      end

      def delete_card(route, method_url, params, headers)
        route =~ method_url
        delete_card_from(:customer, $1, $2, customers)
      end

      def delete_recipient_card(route, method_url, params, headers)
        route =~ method_url
        delete_card_from(:recipient, $1, $2, recipients)
      end

      def update_card(route, method_url, params, headers)
        route =~ method_url
        customer = assert_existence :customer, $1, customers[$1]

        card = assert_existence :card, $2, get_card(customer, $2)
        card.merge!(params)
        card
      end

      private

      def delete_card_from(type, type_id, card_id, objects)
        resource = assert_existence type, type_id, objects[type_id]

        assert_existence :card, card_id, get_card(resource, card_id)

        card = { id: card_id, deleted: true }
        resource[:cards][:data].reject!{|cc|
          cc[:id] == card[:id]
        }
        resource[:default_card] = resource[:cards][:data].count > 0 ? resource[:cards][:data].first[:id] : nil
        card
      end

      def add_card_to(type, type_id, params, objects)
        resource = assert_existence type, type_id, objects[type_id]

        card = card_from_params(params[:card])
        add_card_to_object(type, card, resource)
      end

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
