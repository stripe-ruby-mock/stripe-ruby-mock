
describe 'README examples' do

  before { StripeMock.start }
  after  { StripeMock.stop }

  it "creates a stripe customer" do

    # This doesn't touch stripe's servers nor the internet!
    customer = Stripe::Customer.create({
      email: 'johnny@appleseed.com',
      card: 'void_card_token'
    })
    expect(customer.email).to eq('johnny@appleseed.com')
  end


  it "mocks a declined card error" do
    # Prepares an error for the next stripe request
    StripeMock.prepare_card_error(:card_declined)

    begin
      # Note: The next request of ANY type will raise your prepared error
      Stripe::Charge.create()
    rescue Stripe::CardError => error
      expect(error.http_status).to eq(402)
      expect(error.code).to eq('card_declined')
    end
  end


  it "raises a custom error" do
    custom_error = Stripe::AuthenticationError.new('Did not provide favourite colour', 400)
    StripeMock.prepare_error(custom_error)

    begin
      # Note: The next request of ANY type will raise your prepared error
      Stripe::Invoice.create()
    rescue Stripe::AuthenticationError => error
      expect(error.http_status).to eq(400)
      expect(error.message).to eq('Did not provide favourite colour')
    end
  end

end
