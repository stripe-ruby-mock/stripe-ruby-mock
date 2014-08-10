module StripeMock
  module RequestHandlers
    module Helpers

      def get_customer_card(customer, token)
        customer[:cards][:data].find{|cc| cc[:id] == token }
      end

      def add_card_to_customer(card, cus, replace_current=false)
        card[:customer] = cus[:id]

        if replace_current
          cus[:cards][:data].delete_if {|card| card[:id] == cus[:default_card]}
        else
          cus[:cards][:count] += 1
        end

        cus[:cards][:data] << card
        cus[:default_card] = card[:id] if cus[:cards][:count] == 1

        card
      end

    end
  end
end