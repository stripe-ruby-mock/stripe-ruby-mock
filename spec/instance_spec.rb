require 'spec_helper'

describe StripeMock::Instance do

  before { StripeMock.start }
  after { StripeMock.stop }

  it "handles both string and symbol hash keys" do
    string_params = {
      "id" => "str_abcde",
      :name => "String Plan"
    }
    res = StripeMock.instance.mock_request('post', '/v1/plans', 'api_key', string_params)
    expect(res[:id]).to eq('str_abcde')
    expect(res[:name]).to eq('String Plan')
  end

end
