require 'spec_helper'

describe StripeMock do

  it "overrides stripe's request method" do
    StripeMock.start
    Stripe.request(:xtest, '/', 'abcde') # no error
    StripeMock.stop
  end

  it "reverts overriding stripe's request method" do
    StripeMock.start
    Stripe.request(:xtest, '/', 'abcde') # no error
    StripeMock.stop
    expect { Stripe.request(:x, '/', 'abcde') }.to raise_error
  end

  it "does not persist data between mock sessions" do
    StripeMock.start
    StripeMock.instance.customers[:x] = 9

    StripeMock.stop
    StripeMock.start

    expect(StripeMock.instance.customers[:x]).to be_nil
    expect(StripeMock.instance.customers.keys.length).to eq(0)
    StripeMock.stop
  end

  it "throws an error when trying to prepare an error before starting" do
    expect { StripeMock.prepare_error(StandardError.new) }.to raise_error {|e|
      expect(e).to be_a(StripeMock::UnstartedStateError)
    }

    expect { StripeMock.prepare_card_error(:card_declined) }.to raise_error {|e|
      expect(e).to be_a(StripeMock::UnstartedStateError)
    }
  end

  describe "Test Helper Strategies" do
    before { StripeMock.instance_variable_set("@__test_strat", nil) }

    it "uses mock by default" do
      helper = StripeMock.create_test_helper
      expect(helper).to be_a StripeMock::TestStrategies::Mock
    end

    it "can specify which strategy to use" do
      helper = StripeMock.create_test_helper(:live)
      expect(helper).to be_a StripeMock::TestStrategies::Live

      helper = StripeMock.create_test_helper(:mock)
      expect(helper).to be_a StripeMock::TestStrategies::Mock
    end

    it "throws an error on an unknown strategy" do
      expect { StripeMock.create_test_helper(:lol) }.to raise_error
    end

    it "can configure the default strategy" do
      StripeMock.set_default_test_helper_strategy(:live)
      helper = StripeMock.create_test_helper
      expect(helper).to be_a StripeMock::TestStrategies::Live
    end

    it "can overrige a set default strategy" do
      StripeMock.set_default_test_helper_strategy(:live)
      helper = StripeMock.create_test_helper(:mock)
      expect(helper).to be_a StripeMock::TestStrategies::Mock
    end
  end

end
