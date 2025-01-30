require "spec_helper"

shared_examples "Product API" do
  let(:product_attributes) { {id: "prod_123", name: "My Mock Product"} }
  let(:product) { Stripe::Product.create(product_attributes) }

  it "creates a stripe product" do
    expect(product.id).to eq("prod_123")
    expect(product.name).to eq("My Mock Product")
    expect(product.type).to eq("service")
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
    original = stripe_helper.create_product(product_attributes)
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

    all = Stripe::Product.list
    expect(all.count).to eq(2)
    expect(all.map &:id).to include("prod_123", "prod_456")
    expect(all.map &:name).to include("First Product", "Second Product")
  end

  it 'retrieves products with limit' do
    101.times do |i|
      stripe_helper.create_product(id: "Product #{i}", name: "My Product ##{i}")
    end
    all = Stripe::Product.list(limit: 100)

    expect(all.count).to eq(100)
  end

  context "searching products" do
    # the Search API requires about a minute between writes and reads, so add sleeps accordingly when running live
    it "searches products for exact matches", :aggregate_failures do
      response = Stripe::Product.search({query: 'name:"one"'}, stripe_version: '2020-08-27')
      expect(response.data.size).to eq(0)

      one = stripe_helper.create_product(
        id: "product_1",
        name: "one",
        description: "un",
        shippable: true,
        url: "http://example.com/one",
        metadata: {key: "uno"},
      )
      two = stripe_helper.create_product(
        id: "product_2",
        name: "two",
        active: false,
        description: "deux",
        url: "http://example.com/two",
        metadata: {key: "dos"},
      )

      response = Stripe::Product.search({query: 'active:"true"'}, stripe_version: '2020-08-27')
      expect(response.data.map(&:id)).to match_array([one.id])

      response = Stripe::Product.search({query: 'description:"deux"'}, stripe_version: '2020-08-27')
      expect(response.data.map(&:id)).to match_array([two.id])

      response = Stripe::Product.search({query: 'name:"one"'}, stripe_version: '2020-08-27')
      expect(response.data.map(&:id)).to match_array([one.id])

      response = Stripe::Product.search({query: 'shippable:"true"'}, stripe_version: '2020-08-27')
      expect(response.data.map(&:id)).to match_array([one.id])

      response = Stripe::Product.search({query: 'url:"http://example.com/two"'}, stripe_version: '2020-08-27')
      expect(response.data.map(&:id)).to match_array([two.id])

      response = Stripe::Product.search({query: 'metadata["key"]:"uno"'}, stripe_version: '2020-08-27')
      expect(response.data.map(&:id)).to match_array([one.id])
    end

    it "respects limit", :aggregate_failures do
      11.times do |i|
        stripe_helper.create_product(id: "product_#{i}", name: "Product #{i}")
      end

      response = Stripe::Product.search({query: 'active:"true"'}, stripe_version: '2020-08-27')
      expect(response.data.size).to eq(10)
      response = Stripe::Product.search({query: 'active:"true"', limit: 1}, stripe_version: '2020-08-27')
      expect(response.data.size).to eq(1)
    end

    it "reports search errors", :aggregate_failures do
      expect {
        Stripe::Product.search({limit: 1}, stripe_version: '2020-08-27')
      }.to raise_error(Stripe::InvalidRequestError, /Missing required param: query./)

      expect {
        Stripe::Product.search({query: 'asdf'}, stripe_version: '2020-08-27')
      }.to raise_error(Stripe::InvalidRequestError, /We were unable to parse your search query./)

      expect {
        Stripe::Product.search({query: 'foo:"bar"'}, stripe_version: '2020-08-27')
      }.to raise_error(Stripe::InvalidRequestError, /Field `foo` is an unsupported search field for resource `products`./)
    end
  end

  describe "Validation", :live => true do
    include_context "stripe validator"
    let(:params) { stripe_helper.create_product_params }
    let(:subject) { Stripe::Product.create(params) }
    before { stripe_helper.delete_product(params[:id]) }

    describe "Required Parameters" do
      after do
        params.delete(@attribute_name)
        message = stripe_validator.missing_param_message(@attribute_name)
        expect { subject }.to raise_error(Stripe::InvalidRequestError, message)
      end

      it("requires a name") { @attribute_name = :name }
    end

    describe "Uniqueness" do
      let(:already_exists_message){ stripe_validator.already_exists_message(Stripe::Product) }

      it "validates uniqueness of identifier" do
        stripe_helper.delete_product(params[:id])

        Stripe::Product.create(params)
        expect {
          Stripe::Product.create(params)
        }.to raise_error(Stripe::InvalidRequestError, already_exists_message)
      end
    end
  end

 describe "Mock Data" do
    let(:mock_object) { StripeMock::Data.mock_product }
    let(:known_attributes) { [
      :id,
      :object,
      :active,
      :attributes,
      :caption,
      :created,
      :deactivate_on,
      :description,
      :images,
      :livemode,
      :metadata,
      :name,
      :package_dimensions,
      :shippable,
      :statement_descriptor,
      :type,
      :unit_label,
      :updated,
      :url
    ] }

    it "includes all retreived attributes" do
      expect(mock_object.keys).to eql(known_attributes)
    end
  end

end
