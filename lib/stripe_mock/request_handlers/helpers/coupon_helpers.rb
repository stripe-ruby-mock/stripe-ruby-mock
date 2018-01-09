module StripeMock
  module RequestHandlers
    module Helpers

      def add_coupon_to_customer(customer, coupon)
        customer[:discount] = {
            coupon: coupon,
            customer: customer[:id],
            start: Time.now.to_i,
        }
        customer[:discount][:end] = (DateTime.now >> coupon[:duration_in_months]).to_time.to_i  if coupon[:duration].to_sym == :repeating && coupon[:duration_in_months]

        customer
      end

    end
  end
end