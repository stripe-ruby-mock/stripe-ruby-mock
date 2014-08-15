module StripeMock
  module RequestHandlers
    module Helpers

      def get_card(object, token)
        object[:cards][:data].find{|cc| cc[:id] == token }
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
