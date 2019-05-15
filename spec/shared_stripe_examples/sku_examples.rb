require 'spec_helper'

shared_examples 'SKU API' do

  it "creates a sku" do
    product = Stripe::Product.create(
      :name => 'The Mock Product',
      :type => 'service',
      :description => 'Comfortable cotton t-shirt',
      :attributes => ['size']
    )
    sku = Stripe::SKU.create(
      :id => 'sku_1',
      :attributes => {:size => 'M'},
      :currency => 'usd',
      :inventory => {:type => 'infinite'},
      :price => 1337,
      :product => product.id
    )

    expect(sku.id).to eq('sku_1')
    expect(sku.attributes.size).to eq('M')
    expect(sku.currency).to eq('usd')
    expect(sku.inventory.type).to eq('infinite')
    expect(sku.price).to eq(1337)
    expect(sku.product).to eq(product.id)
  end

  it "creates a sku without specifying ID" do
    product = Stripe::Product.create(
      :name => 'The Mock Product',
      :type => 'service',
      :description => 'Comfortable cotton t-shirt',
      :attributes => ['size']
    )
    sku = Stripe::SKU.create(
      :attributes => {:size => 'M'},
      :currency => 'usd',
      :inventory => {:type => 'infinite'},
      :price => 1337,
      :product => product.id
    )

    expect(sku.id).to_not be(nil)
    expect(sku.attributes.size).to eq('M')
    expect(sku.currency).to eq('usd')
    expect(sku.inventory.type).to eq('infinite')
    expect(sku.price).to eq(1337)
    expect(sku.product).to eq(product.id)
  end

  it "stores a created sku in memory" do
    product = Stripe::Product.create(
      :name => 'The Mock Product',
      :type => 'service',
      :description => 'Comfortable cotton t-shirt',
      :attributes => ['size']
    )
    sku1 = Stripe::SKU.create(
      :attributes => {:size => 'M'},
      :currency => 'usd',
      :inventory => {:type => 'infinite'},
      :price => 1337,
      :product => product.id
    )
    sku2 = Stripe::SKU.create(
      :attributes => {:size => 'L'},
      :currency => 'usd',
      :inventory => {:type => 'infinite'},
      :price => 1337,
      :product => product.id
    )

    data = test_data_source(:skus)

    expect(data[sku1.id]).to_not be_nil
    expect(data[sku1.id][:attributes][:size]).to eq('M')
    expect(data[sku1.id][:currency]).to eq('usd')
    expect(data[sku1.id][:inventory][:type]).to eq('infinite')
    expect(data[sku1.id][:price]).to eq(1337)
    expect(data[sku1.id][:product]).to eq(product.id)

    expect(data[sku2.id]).to_not be_nil
    expect(data[sku2.id][:attributes][:size]).to eq('L')
    expect(data[sku2.id][:currency]).to eq('usd')
    expect(data[sku2.id][:inventory][:type]).to eq('infinite')
    expect(data[sku2.id][:price]).to eq(1337)
    expect(data[sku2.id][:product]).to eq(product.id)
  end

  it "retrieves a sku" do
    original = stripe_helper.create_sku({price: 999})
    sku = Stripe::SKU.retrieve(original.id)

    expect(sku.id).to eq(original.id)
    expect(sku.price).to eq(999)
  end

  it "updates a sku" do
    stripe_helper.create_sku(id: 'sku1', price: 299)

    sku = Stripe::SKU.retrieve('sku1')
    expect(sku.price).to eq(299)

    sku.price = 499
    sku.save

    sku = Stripe::SKU.retrieve('sku1')
    expect(sku.price).to eq(499)
  end

  it "cannot retrieve a sku that doesn't exist" do
    expect { Stripe::SKU.retrieve('nope') }.to raise_error {|e|
      expect(e).to be_a Stripe::InvalidRequestError
      expect(e.param).to eq('sku')
      expect(e.http_status).to eq(404)
    }
  end

  it "deletes a sku" do
    stripe_helper.create_sku(id: 'sku1', price: 299)

    sku = Stripe::SKU.retrieve('sku1')
    expect(sku).to_not be_nil

    sku.delete

    expect { Stripe::SKU.retrieve('sku1') }.to raise_error {|e|
      expect(e).to be_a Stripe::InvalidRequestError
      expect(e.param).to eq('sku')
      expect(e.http_status).to eq(404)
    }
  end

  it "retrieves all skus" do
    stripe_helper.create_sku(id: 'sku1', price: 299)
    stripe_helper.create_sku(id: 'sku2', price: 399)

    all = Stripe::SKU.all
    expect(all.count).to eq(2)
    expect(all.map &:id).to include('sku1', 'sku2')
    expect(all.map &:price).to include(299, 399)
  end

  it 'retrieves skus with limit' do
    11.times do | i|
      stripe_helper.create_sku(id: "sku#{i}", price: i)
    end
    all = Stripe::SKU.all(limit: 10)

    expect(all.count).to eq(10)
  end

  it 'validates the inventory type' do
    expect {
      sku1 = Stripe::SKU.create(
        :attributes => {:size => 'M'},
        :currency => 'usd',
        :inventory => {:type => 'bad'},
        :price => 1337,
        :product => 'prod_1'
      )
    }.to raise_error(Stripe::InvalidRequestError, "Invalid inventory type: must be one of finite, infinite, or bucket")
  end

  describe "Validation", :live => true do
    let(:params) { stripe_helper.create_sku_params }
    let(:subject) { Stripe::SKU.create(params) }

    describe "Required Parameters" do
      after do
        params.delete(@name)
        message = "Missing required param: #{@name}."
        expect { subject }.to raise_error(Stripe::InvalidRequestError, message)
      end

      it("requires a currency") { @name = :currency }
      it("requires an inventory") { @name = :inventory }
      it("requires a price") { @name = :price }
      it("requires an product") { @name = :product }
    end

    describe "Uniqueness" do
      it "validates for uniqueness" do
        stripe_helper.delete_sku(params[:id])

        Stripe::SKU.create(params)
        expect {
          Stripe::SKU.create(params)
        }.to raise_error(Stripe::InvalidRequestError, "SKU already exists.")
      end
    end
  end

end
