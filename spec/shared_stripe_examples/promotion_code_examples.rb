require "spec_helper"

shared_examples "PromotionCode API" do
  let(:coupon) { stripe_helper.create_coupon }

  it "creates a promotion code" do
    promotion_code = Stripe::PromotionCode.create({id: "promo_123", coupon: coupon.id, code: "FREESTUFF"})

    expect(promotion_code.id).to eq("promo_123")
    expect(promotion_code.code).to eq("FREESTUFF")
    expect(promotion_code.coupon).to eq(coupon.id)
  end

  it "creates a promotion code without specifying code" do
    promotion_code = Stripe::PromotionCode.create({id: "promo_123", coupon: coupon.id})

    expect(promotion_code.id).to eq("promo_123")
    expect(promotion_code.code).to eq("TESTCODE")
    expect(promotion_code.coupon).to eq(coupon.id)
  end

  it "cannot create a promotion code without a coupon" do
    expect {
      Stripe::PromotionCode.create
    }.to raise_error { |e|
      expect(e).to be_a(Stripe::InvalidRequestError)
      expect(e.message).to eq("Missing required param: coupon")
    }
  end

  it "requires minimum amount currency when minimum amount is provided" do
    expect {
      Stripe::PromotionCode.create(coupon: coupon, restrictions: {minimum_amount: 100})
    }.to raise_error { |e|
      expect(e).to be_a(Stripe::InvalidRequestError)
      expect(e.message).to eq("You must pass minimum_amount_currency when passing minimum_amount")
    }
  end

  it "updates a promotion code" do
    promotion_code = Stripe::PromotionCode.create({coupon: coupon.id})
    expect(promotion_code.active).to eq(true)

    updated = Stripe::PromotionCode.update(promotion_code.id, active: false)

    expect(updated.active).to eq(false)
  end

  it "retrieves a promotion code" do
    original = Stripe::PromotionCode.create({coupon: coupon.id})

    promotion_code = Stripe::PromotionCode.retrieve(original.id)

    expect(promotion_code.id).to eq(original.id)
    expect(promotion_code.code).to eq(original.code)
    expect(promotion_code.coupon).to eq(original.coupon)
  end

  it "lists all promotion codes" do
    Stripe::PromotionCode.create({coupon: coupon.id, code: "10PERCENT"})
    Stripe::PromotionCode.create({coupon: coupon.id, code: "20PERCENT"})

    all = Stripe::PromotionCode.list

    expect(all.count).to eq(2)
    expect(all.map(&:code)).to include("10PERCENT", "20PERCENT")
  end
end
