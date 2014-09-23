module StripeMock
  module RequestHandlers
    module Helpers

      def get_customer_card(customer, token)
        customer[:cards][:data].find{|cc| cc[:id] == token }
      end

      def add_card_to_customer(card, cus, replace_default = false)
        card[:customer] = cus[:id]

        if cus[:cards][:count] == 0
          cus[:cards][:count] += 1
        elsif cus[:cards][:count] > 0 && replace_default
          cus[:cards][:data].delete_if {|card| card[:id] == cus[:default_card]}
        end

        cus[:cards][:data] << card

        card
      end

    end
  end
end