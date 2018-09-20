require "spec_helper"

shared_examples "Product API" do

  let(:product_attributes){ {
    id: "prod_123",
    name: "My Mock Product",
    type: "service",
    unit_label: "my_unit"
  } }
  let(:idless_attributes){ product_attributes.merge({id: nil}) }

  it "creates a stripe product" do
    product = Stripe::Product.create(product_attributes)
    expect(product.id).to eq("prod_123")
    expect(product.name).to eq("My Mock Product")
    expect(product.type).to eq("service")
    expect(product.unit_label).to eq("my_unit")
  end

  it "creates a stripe product without specifying ID" do
    expect(idless_attributes[:id]).to be_nil

    product = Stripe::Product.create(idless_attributes)
    expect(product.id).to match(/^test_product_1/)
  end

  it "stores a created stripe product in memory" do
    product = Stripe::Product.create(product_attributes)
    product2 = Stripe::Product.create(product_attributes.merge({id: "prod_456", name: "My Other Product"}))

    data = test_data_source(:products)
    expect(data[product.id]).to_not be_nil
    expect(data[product.id][:id]).to eq("prod_123")
    expect(data[product.id][:name]).to eq("My Mock Product")
    expect(data[product2.id]).to_not be_nil
    expect(data[product2.id][:id]).to eq("prod_456")
    expect(data[product2.id][:name]).to eq("My Other Product")
  end

  it "retrieves a stripe product" do
    original = stripe_helper.create_product(idless_attributes)
    product = Stripe::Product.retrieve(original.id)

    expect(product.id).to eq(original.id)
    expect(product.name).to eq(original.name)
  end

  it "updates a stripe product" do
    stripe_helper.create_product(id: "prod_XYZ", name: "Future Product")

    product = Stripe::Product.retrieve("prod_XYZ")
    expect(product.name).to eq("Future Product")

    product.name = "Updated Product"
    product.save
    product = Stripe::Product.retrieve("prod_XYZ")
    expect(product.name).to eq("Updated Product")
  end

  it "cannot retrieve a stripe product that doesn't exist" do
    expect { Stripe::Product.retrieve('nope') }.to raise_error {|e|
      expect(e).to be_a Stripe::InvalidRequestError
      expect(e.param).to eq("product")
      expect(e.http_status).to eq(404)
    }
  end

  it "deletes a stripe product" do
    stripe_helper.create_product(id: "prod_DEL", name: "Aging Product")

    product = Stripe::Product.retrieve("prod_DEL")
    expect(product).to_not be_nil

    product.delete

    expect { Stripe::Product.retrieve("prod_DEL") }.to raise_error {|e|
      expect(e).to be_a Stripe::InvalidRequestError
      expect(e.param).to eq("product")
      expect(e.http_status).to eq(404)
    }
  end

  it "retrieves all products" do
    stripe_helper.create_product(id: "prod_123", name: "First Product")
    stripe_helper.create_product(id: "prod_456", name: "Second Product")

    all = Stripe::Product.all
    expect(all.count).to eq(2)
    expect(all.map &:id).to include("prod_123", "prod_456")
    expect(all.map &:name).to include("First Product", "Second Product")
  end

  it 'retrieves products with limit' do
    101.times do |i|
      stripe_helper.create_product(id: "Product #{i}", name: "My Product ##{i}")
    end
    all = Stripe::Product.all(limit: 100)

    expect(all.count).to eq(100)
  end

  #it 'validates the amount' do
  #  expect {
  #    Stripe::Product.create(
  #      :id => 'pid_1',
  #      :name => 'The Mock Plan',
  #      :amount => 99.99,
  #      :currency => 'USD',
  #      :interval => 'month'
  #    )
  #  }.to raise_error(Stripe::InvalidRequestError, "Invalid integer: 99.99")
  #end

  describe "Validation", :live => true do
    let(:params) { stripe_helper.create_product_params }
    let(:subject) { Stripe::Product.create(params) }

    #describe "Required Parameters" do
    #  after do
    #    params.delete(@name)
    #    message =
    #      if @name == :amount
    #        "Plans require an `#{@name}` parameter to be set."
    #      else
    #        "Missing required param: #{@name}."
    #      end
    #    expect { subject }.to raise_error(Stripe::InvalidRequestError, message)
    #  end
#
    #  it("requires a name") { @name = :name }
    #  it("requires an amount") { @name = :amount }
    #  it("requires a currency") { @name = :currency }
    #  it("requires an interval") { @name = :interval }
    #end

    describe "Uniqueness" do
      it "validates for uniqueness" do
        stripe_helper.delete_product(params[:id])

        Stripe::Product.create(params)
        expect {
          Stripe::Product.create(params)
        }.to raise_error(Stripe::InvalidRequestError, "Product already exists.")
      end
    end
  end

end
