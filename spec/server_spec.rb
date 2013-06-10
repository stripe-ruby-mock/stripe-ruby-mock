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


  it "uses an RPC client for mock requests" do
    StripeMock.start_client
    charge = Stripe::Charge.create(
      amount: 987,
      currency: 'USD',
      card: 'card_token_abcde',
      description: 'card charge'
    )
    expect(charge.amount).to eq(987)
    expect(charge.currency).to eq('USD')
    expect(charge.description).to eq('card charge')
    StripeMock.stop_client
  end


  it "should not clear server data in between client sessions by default" do
    StripeMock.start_client
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

    StripeMock.stop_client
  end


  it "can toggle debug" do
    StripeMock.start_client

    StripeMock.set_server_debug(true)
    StripeMock.set_server_debug(false)
    StripeMock.set_server_debug(true)

    StripeMock.stop_client
  end


  it "throws an error when server is not running" do
    begin
      StripeMock.start_client(1515)
      # We should never get here
      expect(false).to eq(true)
    rescue StripeMock::ServerTimeoutError => e
      expect(e.associated_error).to be_a(Errno::ECONNREFUSED)
    end
  end

end
