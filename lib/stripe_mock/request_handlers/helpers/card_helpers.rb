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
          object[:cards][:count] += 1
        end

        object[:default_card] = card[:id] unless object[:default_card]
        object[:cards][:data] << card

        card
      end

    end
  end
end
