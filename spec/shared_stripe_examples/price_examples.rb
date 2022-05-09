require 'spec_helper'

shared_examples 'Price API' do
  let(:product) { stripe_helper.create_product }
  let(:product_id) { product.id }

  let(:price_attributes) { {
    :id => "price_abc123",
    :product => product_id,
    :nickname => "My Mock price",
    :amount => 9900,
    :currency => "usd",
    :interval => "month"
  } }
  let(:price) { Stripe::Price.create(price_attributes) }

  let(:price_attributes_without_id){ price_attributes.merge(id: nil) }
  let(:price_without_id){ Stripe::Price.create(price_attributes_without_id) }

  let(:price_attributes_with_trial) { price_attributes.merge(id: "prod_TRIAL", :trial_period_days => 30) }
  let(:price_with_trial) { Stripe::Price.create(price_attributes_with_trial) }

  let(:metadata) { {:description => "desc text", :info => "info text"} }
  let(:price_attributes_with_metadata) { price_attributes.merge(id: "prod_META", metadata: metadata) }
  let(:price_with_metadata) { Stripe::Price.create(price_attributes_with_metadata) }

  before(:each) do
    product
  end

  it "creates a stripe price" do
    expect(price.id).to eq('price_abc123')
    expect(price.nickname).to eq('My Mock price')
    expect(price.amount).to eq(9900)

    expect(price.currency).to eq('usd')
    expect(price.interval).to eq("month")

    expect(price_with_metadata.metadata.description).to eq('desc text')
    expect(price_with_metadata.metadata.info).to eq('info text')

    expect(price_with_trial.trial_period_days).to eq(30)
  end

  it "creates a stripe price without specifying ID" do
    expect(price_attributes_without_id[:id]).to be_nil
    expect(price_without_id.id).to match(/^test_price_1/)
  end

  it "stores a created stripe price in memory" do
    price
    price2 = Stripe::Price.create(price_attributes.merge(id: "price_def456", amount: 299))

    data = test_data_source(:prices)
    expect(data[price.id]).to_not be_nil
    expect(data[price.id][:amount]).to eq(9900)
    expect(data[price2.id]).to_not be_nil
    expect(data[price2.id][:amount]).to eq(299)
  end

  it "retrieves a stripe price" do
    original = stripe_helper.create_price(product: product_id, amount: 1331, id: 'price_943843')
    price = Stripe::Price.retrieve(original.id)

    expect(price.id).to eq(original.id)
    expect(price.amount).to eq(original.amount)
  end

  it "updates a stripe price" do
    stripe_helper.create_price(id: 'super_member', product: product_id, amount: 111)

    price = Stripe::Price.retrieve('super_member')
    expect(price.amount).to eq(111)

    price.amount = 789
    price.save
    price = Stripe::Price.retrieve('super_member')
    expect(price.amount).to eq(789)
  end

  it "cannot retrieve a stripe price that doesn't exist" do
    expect { Stripe::Price.retrieve('nope') }.to raise_error {|e|
      expect(e).to be_a Stripe::InvalidRequestError
      expect(e.param).to eq('price')
      expect(e.http_status).to eq(404)
    }
  end

  it "retrieves all prices" do
    stripe_helper.create_price(id: 'price One', product: product_id, amount: 54321)
    stripe_helper.create_price(id: 'price Two', product: product_id, amount: 98765)

    all = Stripe::Price.list
    expect(all.count).to eq(2)
    expect(all.map &:id).to include('price One', 'price Two')
    expect(all.map &:amount).to include(54321, 98765)
  end

  it 'retrieves prices with limit' do
    101.times do | i|
      stripe_helper.create_price(id: "price #{i}", product: product_id, amount: 11)
    end
    all = Stripe::Price.list(limit: 100)

    expect(all.count).to eq(100)
  end

  it "retrieves prices with lookup keys" do
    stripe_helper.create_price(id: 'price One', product: product_id, amount: 54321, lookup_key: 'one')
    stripe_helper.create_price(id: 'price Two', product: product_id, amount: 98765, lookup_key: 'two')

    all = Stripe::Price.list({lookup_keys: ['one', 'two']})
    expect(all.count).to eq(2)
    expect(all.map &:id).to include('price One', 'price Two')
    expect(all.map &:amount).to include(54321, 98765)

    one = Stripe::Price.list({lookup_keys: ['one']})
    expect(one.count).to eq(1)
    expect(one.map &:id).to include('price One')
    expect(one.map &:amount).to include(54321)

    two = Stripe::Price.list({lookup_keys: ['two']})
    expect(two.count).to eq(1)
    expect(two.map &:id).to include('price Two')
    expect(two.map &:amount).to include(98765)
  end

  context "searching prices" do
    # the Search API requires about a minute between writes and reads, so add sleeps accordingly when running live
    it "searches prices for exact matches", :aggregate_failures do
      response = Stripe::Price.search({query: 'currency:"usd"'}, stripe_version: '2020-08-27')
      expect(response.data.size).to eq(0)

      one = stripe_helper.create_price(
        amount: 100,
        currency: 'usd',
        lookup_key: 'one',
        product: product_id,
        metadata: {key: 'uno'},
        type: "one_time",
      )
      two = stripe_helper.create_price(
        active: false,
        amount: 200,
        currency: 'gbp',
        lookup_key: 'two',
        product: product_id,
        recurring: {interval: 'month'},
        metadata: {key: 'dos'},
      )

      response = Stripe::Price.search({query: 'active:"true"'}, stripe_version: '2020-08-27')
      expect(response.data.map(&:id)).to match_array([one.id])

      response = Stripe::Price.search({query: 'currency:"gbp"'}, stripe_version: '2020-08-27')
      expect(response.data.map(&:id)).to match_array([two.id])

      response = Stripe::Price.search({query: 'lookup_key:"one"'}, stripe_version: '2020-08-27')
      expect(response.data.map(&:id)).to match_array([one.id])

      response = Stripe::Price.search({query: %(product:"#{product.id}")}, stripe_version: '2020-08-27')
      expect(response.data.map(&:id)).to match_array([one.id, two.id])

      response = Stripe::Price.search({query: 'type:"recurring"'}, stripe_version: '2020-08-27')
      expect(response.data.map(&:id)).to match_array([two.id])

      response = Stripe::Price.search({query: 'metadata["key"]:"uno"'}, stripe_version: '2020-08-27')
      expect(response.data.map(&:id)).to match_array([one.id])
    end

    it "respects limit", :aggregate_failures do
      11.times do
        stripe_helper.create_price(product: product_id)
      end

      response = Stripe::Price.search({query: %(product:"#{product.id}")}, stripe_version: '2020-08-27')
      expect(response.data.size).to eq(10)
      response = Stripe::Price.search({query: %(product:"#{product.id}"), limit: 1}, stripe_version: '2020-08-27')
      expect(response.data.size).to eq(1)
    end

    it "reports search errors", :aggregate_failures do
      expect {
        Stripe::Price.search({limit: 1}, stripe_version: '2020-08-27')
      }.to raise_error(Stripe::InvalidRequestError, /Missing required param: query./)

      expect {
        Stripe::Price.search({query: 'asdf'}, stripe_version: '2020-08-27')
      }.to raise_error(Stripe::InvalidRequestError, /We were unable to parse your search query./)

      expect {
        Stripe::Price.search({query: 'foo:"bar"'}, stripe_version: '2020-08-27')
      }.to raise_error(Stripe::InvalidRequestError, /Field `foo` is an unsupported search field for resource `prices`./)
    end
  end

  describe "Validations", :live => true do
    include_context "stripe validator"
    let(:params) { stripe_helper.create_price_params(product: product_id) }
    let(:subject) { Stripe::Price.create(params) }

    describe "Associations" do
      let(:not_found_product_id){ "prod_NONEXIST" }
      let(:not_found_message) { stripe_validator.not_found_message(Stripe::Product, not_found_product_id) }
      let(:params) { stripe_helper.create_price_params(product: not_found_product_id) }
      let(:products) { stripe_helper.list_products(100).data }

      it "validates associated product" do
        expect(products.map(&:id)).to_not include(not_found_product_id)
        expect { subject }.to raise_error(Stripe::InvalidRequestError, not_found_message)
      end
    end

    describe "Presence" do
      after do
        params.delete(@name)
        message = "Missing required param: #{@name}."
        expect { subject }.to raise_error(Stripe::InvalidRequestError, message)
      end

      it("validates presence of currency") { @name = :currency }
    end
  end

  describe "Mock Data" do
    let(:mock_object) { StripeMock::Data.mock_price }
    let(:known_attributes) { [
        :id,
        :object,
        :active,
        :billing_scheme,
        :created,
        :currency,
        :livemode,
        :lookup_key,
        :metadata,
        :nickname,
        :product,
        :recurring,
        :tiers_mode,
        :transform_quantity,
        :type,
        :unit_amount,
        :unit_amount_decimal
    ] }

    it "includes all retreived attributes" do
      expect(mock_object.keys).to eql(known_attributes)
    end
  end

end
