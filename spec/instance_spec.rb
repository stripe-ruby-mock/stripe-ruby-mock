require 'spec_helper'
require_stripe_examples

describe StripeMock::Instance do

  let(:stripe_helper) { StripeMock.create_test_helper }

  it_behaves_like_stripe do
    def test_data_source(type); StripeMock.instance.send(type); end
  end

  before { StripeMock.start }
  after { StripeMock.stop }

  it "handles both string and symbol hash keys" do
    string_params = stripe_helper.create_plan_params(
      "id" => "str_abcde",
      :name => "String Plan"
    )
    res, api_key = StripeMock.instance.mock_request('post', '/v1/plans', 'api_key', string_params)
    expect(res[:id]).to eq('str_abcde')
    expect(res[:name]).to eq('String Plan')
  end

  it "exits gracefully on an unrecognized handler url" do
    dummy_params = {
      "id" => "str_12345",
      "name" => "PLAN"
    }

    expect { res, api_key = StripeMock.instance.mock_request('post', '/v1/unrecongnized_method', 'api_key', dummy_params) }.to_not raise_error
  end

  it "can toggle debug" do
    StripeMock.toggle_debug(true)
    expect(StripeMock.instance.debug).to eq(true)
    StripeMock.toggle_debug(false)
    expect(StripeMock.instance.debug).to eq(false)
  end

  it "should toggle off debug when mock session ends" do
    StripeMock.toggle_debug(true)

    StripeMock.stop
    expect(StripeMock.instance).to be_nil

    StripeMock.start
    expect(StripeMock.instance.debug).to eq(false)
  end
end
