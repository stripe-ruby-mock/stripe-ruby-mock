module StripeMock
  module RequestHandlers
    module Helpers

      def get_card(object, card_id, class_name='Customer')
        card = object[:cards][:data].find{|cc| cc[:id] == card_id }
        if card.nil?
          msg = "#{class_name} #{object[:id]} does not have card #{card_id}"
          raise Stripe::InvalidRequestError.new(msg, 'card', 404)
        end
        card
      end

      def add_card_to_object(type, card, object, replace_current=false)
        card[type] = object[:id]

        if replace_current
          object[:cards][:data].delete_if {|card| card[:id] == object[:default_card]}
          object[:default_card] = card[:id]
        else
          object[:cards][:total_count] += 1
        end

        object[:default_card] = card[:id] unless object[:default_card]
        object[:cards][:data] << card

        card
      end

      def retrieve_object_cards(type, type_id, objects)
        resource = assert_existence type, type_id, objects[type_id]
        cards = resource[:cards]

        Data.mock_list_object(cards[:data])
      end

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
