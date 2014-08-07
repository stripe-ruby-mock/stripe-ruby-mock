module StripeMock
  module RequestHandlers
    module Helpers

      def get_customer_card(customer, token)
        customer[:cards][:data].find{|cc| cc[:id] == token }
      end

      def add_card_to_customer(card, cus)
        card[:customer] = cus[:id]

        if cus[:cards][:count] == 0
          cus[:cards][:count] += 1
        else
          cus[:cards][:data].delete_if {|card| card[:id] == cus[:default_card]}
        end

        cus[:cards][:data] << card

        card
      end

      def add_refund_to_charge(refund, charge)
        refund[:charge] = charge[:id]

        if charge[:refunds][:count] == 0
          charge[:refunds][:count] += 1
        end

        charge[:refunds][:data] << refund

        refund
      end

    end
  end
end
