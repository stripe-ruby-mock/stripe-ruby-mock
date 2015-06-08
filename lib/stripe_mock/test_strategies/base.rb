module StripeMock
  module TestStrategies
    class Base

      def create_plan_params(params={})
        {
          :id => 'stripe_mock_default_plan_id',
          :name => 'StripeMock Default Plan ID',
          :amount => 1337,
          :currency => 'usd',
          :interval => 'month'
        }.merge(params)
      end

      def generate_card_token(card_params={})
        card_data = { :number => "4242424242424242", :exp_month => 9, :exp_year => 2018, :cvc => "999" }
        card = StripeMock::Util.card_merge(card_data, card_params)
        card[:fingerprint] = StripeMock::Util.fingerprint(card[:number])

        stripe_token = Stripe::Token.create(:card => card)
        stripe_token.id
      end

      def create_coupon_params(params = {})
        {
          id: '10BUCKS',
          amount_off: 1000,
          currency: 'usd',
          max_redemptions: 100,
          metadata: {
            created_by: 'admin_acct_1'
          },
          duration: 'once'
        }.merge(params)
      end

      def create_coupon_percent_of_params(params = {})
        {
          id: '25PERCENT',
          percent_off: 25,
          redeem_by: nil,
          duration_in_months: 3,
          duration: :repeating
        }.merge(params)
      end

      def create_coupon(params = {})
        Stripe::Coupon.create create_coupon_params(params)
      end

      def delete_all_coupons
        coupons = Stripe::Coupon.all
        coupons.data.map(&:delete) if coupons.data.count > 0
      end
    end
  end
end
