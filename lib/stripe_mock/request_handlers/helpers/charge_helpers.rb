module StripeMock
  module RequestHandlers
    module Helpers

      def add_refund_to_charge(refund, charge)
        if refund[:amount] + charge[:amount_refunded] > charge[:amount]
          raise Stripe::InvalidRequestError.new(
            "Charge #{charge[:id]} has already been refunded.",
            'amount'
          )
        end
        refunds = charge[:refunds]
        refunds[:data] << refund
        refunds[:total_count] = refunds[:data].count

        charge[:amount_refunded] = refunds[:data].reduce(0) {|sum, r| sum + r[:amount].to_i }
        charge[:refunded] = true
      end

    end
  end
end
