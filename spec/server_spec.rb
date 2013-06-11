require 'spec_helper'

describe 'StripeMock Server' do

  before(:all) do
    Dante::Runner.new('stripe-mock-server').execute(
      :daemonize => true, :pid_path => './stripe-mock-server.pid'
    ){
      StripeMock.start_server(4999)
    }
  end

  after(:all) do
    Dante::Runner.new('stripe-mock-server').execute(
      :kill => true, :pid_path => './stripe-mock-server.pid'
    )
  end


  before { StripeMock.start_client }
  after  { StripeMock.stop_client }


  it "uses an RPC client for mock requests" do
    charge = Stripe::Charge.create(
      amount: 987,
      currency: 'USD',
      card: 'card_token_abcde',
      description: 'card charge'
    )
    expect(charge.amount).to eq(987)
    expect(charge.currency).to eq('USD')
    expect(charge.description).to eq('card charge')
  end


  it "should not clear server data in between client sessions by default" do
    customer = Stripe::Customer.create(email: 'johnny@appleseed.com')
    expect(customer.email).to eq('johnny@appleseed.com')

    server_customer_data = StripeMock.get_server_data(:customers)[customer.id]
    expect(server_customer_data).to_not be_nil
    expect(server_customer_data['email']).to eq('johnny@appleseed.com')

    StripeMock.stop_client
    StripeMock.start_client

    server_customer_data = StripeMock.get_server_data(:customers)[customer.id]
    expect(server_customer_data).to_not be_nil
    expect(server_customer_data['email']).to eq('johnny@appleseed.com')
  end

  it "returns a response with symbolized hash keys" do
    response = StripeMock.redirect_to_mock_server('get', '/v1/plans/x', 'xxx')
    response.keys.each {|k| expect(k).to be_a(Symbol) }
  end

  it "can toggle debug" do

    StripeMock.set_server_debug(true)
    StripeMock.set_server_debug(false)
    StripeMock.set_server_debug(true)
  end


  it "throws an error when server is not running" do
    StripeMock.stop_client
    begin
      StripeMock.start_client(1515)
      # We should never get here
      expect(false).to eq(true)
    rescue StripeMock::ServerTimeoutError => e
      expect(e.associated_error).to be_a(Errno::ECONNREFUSED)
    end
  end

end
