require 'spec_helper'

shared_examples 'Coupon API' do

  let(:percent_off_attributes) do
    {
      :id => '25PERCENT',
      :percent_off => 25,
      :redeem_by => nil,
      :duration_in_months => 3,
    }
  end

  it "creates a stripe coupon" do
    coupon = Stripe::Coupon.create(
      :id => '10BUCKS',
      :amount_off => 1000,
      :currency => 'USD',
      :max_redemptions => 100,
      :metadata => {
        :created_by => 'admin_acct_1',
      },
    )

    expect(coupon.id).to eq('10BUCKS')
    expect(coupon.amount_off).to eq(1000)

    expect(coupon.currency).to eq('USD')
    expect(coupon.max_redemptions).to eq(100)
    expect(coupon.metadata.to_hash).to eq( { :created_by => 'admin_acct_1' } )
  end


  it "stores a created stripe coupon in memory" do
    coupon = Stripe::Coupon.create(
      :id => '10BUCKS',
      :amount_off => 1000,
      :currency => 'USD',
      :redeem_by => nil,
      :max_redemptions => 100,
      :metadata => {
        :created_by => 'admin_acct_1',
      },
    )
    coupon2 = Stripe::Coupon.create(percent_off_attributes)

    data = test_data_source(:coupons)
    expect(data[coupon.id]).to_not be_nil
    expect(data[coupon.id][:amount_off]).to eq(1000)

    expect(data[coupon2.id]).to_not be_nil
    expect(data[coupon2.id][:percent_off]).to eq(25)
  end


  it "retrieves a stripe coupon" do
    original = Stripe::Coupon.create(percent_off_attributes)
    coupon = Stripe::Coupon.retrieve(original.id)

    expect(coupon.id).to eq(original.id)
    expect(coupon.percent_off).to eq(original.percent_off)
  end


  it "cannot retrieve a stripe coupon that doesn't exist" do
    expect { Stripe::Coupon.retrieve('nope') }.to raise_error {|e|
      expect(e).to be_a Stripe::InvalidRequestError
      expect(e.param).to eq('coupon')
      expect(e.http_status).to eq(404)
    }
  end

  it "deletes a stripe coupon" do
    original = Stripe::Coupon.create(percent_off_attributes)
    coupon = Stripe::Coupon.retrieve(original.id)

    coupon.delete

    expect { Stripe::Coupon.retrieve(original.id) }.to raise_error {|e|
      expect(e).to be_a Stripe::InvalidRequestError
      expect(e.param).to eq('coupon')
      expect(e.http_status).to eq(404)
    }
  end

  it "retrieves all coupons" do
    Stripe::Coupon.create({ id: 'Coupon One', amount_off: 1500 })
    Stripe::Coupon.create({ id: 'Coupon Two', amount_off: 3000 })

    all = Stripe::Coupon.all
    expect(all.length).to eq(2)
    all.map(&:id).should include('Coupon One', 'Coupon Two')
    all.map(&:amount_off).should include(1500, 3000)
  end


  context "With strict mode toggled off" do

    before { StripeMock.toggle_strict(false) }

    it "can retrieve a stripe coupon with an id that doesn't exist" do
      coupon = Stripe::Coupon.retrieve('test_coupon_x')

      expect(coupon.id).to eq('test_coupon_x')
      expect(coupon.percent_off).to_not be_nil
      expect(coupon.valid).to be_true
    end
  end

end
