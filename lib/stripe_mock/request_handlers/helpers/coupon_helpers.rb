module StripeMock
  module RequestHandlers
    module Helpers

      def add_coupon_to_customer(customer, coupon)
        customer[:discount] = { coupon: coupon }

        customer
      end

    end
  end
end