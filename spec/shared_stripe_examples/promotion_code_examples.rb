require 'spec_helper'

shared_examples 'PromotionCode API' do
  let(:coupon) { stripe_helper.create_coupon }

  before do
    Stripe::PromotionCode.create({
      id: 'promo_test',
      coupon: coupon,
      code: 'TEST'
    })
  end

  context 'create promotion code' do
    it 'creates a stripe promotion code' do
      promo_code = Stripe::PromotionCode.create({
        coupon: coupon,
        code: 'TEST'
      })

      expect(promo_code.object).to eq('promotion_code')
      expect(promo_code.code).to eq('TEST')
      expect(promo_code.coupon.id).to eq(coupon.id)
    end
  end

  context 'updating a promotion code' do
    it 'updates a stripe promotion code' do
      promo_code = Stripe::PromotionCode.update(
        'promo_test',
        { active: false }
      )

      expect(promo_code.active).to eq(false)
      expect(promo_code.id).to eq('promo_test')
    end
  end

  context 'list promotion codes' do
    before do
      Stripe::PromotionCode.create({
        coupon: coupon,
        code: 'TEST2'
      })
    end

    it 'contains multiple promotion codes' do
      promos = Stripe::PromotionCode.list

      expect(promos.object).to eq('list')
      expect(promos.count).to eq(2)
      expect(promos.data.length).to eq(2)
    end
  end

  context 'get promotion code' do
    it 'retreives a stripe promotion code' do
      promo = Stripe::PromotionCode.retrieve('promo_test')

      expect(promo.id).to eq('promo_test')
    end
  end
end
