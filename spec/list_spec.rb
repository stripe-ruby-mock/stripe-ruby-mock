require "spec_helper"

describe StripeMock::Data::List do
  before :all do
    StripeMock.start
  end

  after :all do
    StripeMock.stop
  end

  it "contains data" do
    obj = double
    obj2 = double
    obj3 = double
    list = StripeMock::Data::List.new([obj, obj2, obj3])

    expect(list.data).to eq([obj, obj2, obj3])
  end

  it "can accept a single object" do
    list = StripeMock::Data::List.new(double)

    expect(list.data).to be_kind_of(Array)
    expect(list.data.size).to eq(1)
  end

  it "infers object type for url" do
    customer = Stripe::Customer.create
    list = StripeMock::Data::List.new([customer])

    expect(list.url).to eq("/v1/customers")
  end

  it "eventually gets turned into a hash" do
    charge1 = Stripe::Charge.create
    charge2 = Stripe::Charge.create
    charge3 = Stripe::Charge.create
    list = StripeMock::Data::List.new([charge1, charge2, charge3])
    hash = list.to_h

    expect(hash).to eq(
      object: "list",
      data: [charge1, charge2, charge3],
      url: "/v1/charges",
      has_more: false
    )
  end

  it "delegates other methods to hash keys" do
    list = StripeMock::Data::List.new([double, double, double])

    expect(list).to respond_to(:data)
    expect(list.data).to be_kind_of(Array)
    expect(list.object).to eq("list")
    expect(list.has_more).to eq(false)
    expect(list.url).to eq("/v1/doubles")
    expect { list.foobar }.to raise_error(NoMethodError)
  end

  context "with a limit" do
    it "accepts a limit which is reflected in the data returned" do
      list = StripeMock::Data::List.new([double] * 25)

      expect(list.to_h[:data].size).to eq(10)

      list = StripeMock::Data::List.new([double] * 25, limit: 15)

      expect(list.limit).to eq(15)
      expect(list.to_h[:data].size).to eq(15)
    end

    it "defaults to a limit of 10" do
      list = StripeMock::Data::List.new([])

      expect(list.limit).to eq(10)
    end

    it "won't accept a limit of > 100" do
      list = StripeMock::Data::List.new([], limit: 105)

      expect(list.limit).to eq(100)
    end

    it "won't accept a limit of < 1" do
      list = StripeMock::Data::List.new([], limit: 0)

      expect(list.limit).to eq(1)

      list = StripeMock::Data::List.new([], limit: -4)

      expect(list.limit).to eq(1)
    end
  end

  context "pagination" do
    it "has a has_more field when it has more" do
      list = StripeMock::Data::List.new([Stripe::Charge.create] * 256)

      expect(list).to have_more
    end

    it "accepts a starting_after parameter" do
      data = []
      255.times { data << Stripe::Charge.create }
      new_charge = Stripe::Charge.create
      data[89] = new_charge
      list = StripeMock::Data::List.new(data, starting_after: new_charge.id)
      hash = list.to_h

      expect(hash[:data].size).to eq(10)
      expect(hash[:data]).to eq(data[90, 10])
    end

    it "raises an error if starting_after cursor is not found" do
      data = []
      255.times { data << Stripe::Charge.create }
      list = StripeMock::Data::List.new(data, starting_after: "test_ch_unknown")

      expect { list.to_h }.to raise_error
    end
  end
end
