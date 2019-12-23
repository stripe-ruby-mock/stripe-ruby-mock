module StripeMock
  module RequestHandlers
    module Helpers

      def add_refund_to_payment_intent(refund, payment_intent)
        refunds = payment_intent[:refunds]
        refunds[:data] << refund
        refunds[:total_count] = refunds[:data].count

        payment_intent[:amount_refunded] = refunds[:data].reduce(0) {|sum, r| sum + r[:amount].to_i }
        payment_intent[:refunded] = true
      end

    end
  end
end
