# stripe-ruby-mock

* Homepage: https://github.com/mindeavor/stripe-ruby-mock
* Issues: https://github.com/mindeavor/stripe-ruby-mock/issues

## Install

    $ gem install stripe-ruby-mock

## Features

* No stripe server access required
* Easily test against stripe errors

## Description

** *WARNING: THIS LIBRARY IS INCOMPLETE AND IN ACTIVE DEVELOPMENT* **

At its core, this library overrides [stripe-ruby's](https://github.com/stripe/stripe-ruby)
request method to skip all http calls and
instead directly return test data. This allows you to write and run tests
without the need to actually hit stripe's servers.

You can use stripe-ruby-mock with any ruby testing library. Here's a quick dummy example with RSpec:

```ruby
require 'stripe_mock'

describe MyApp do
  before { StripeMock.start }
  after { StripeMock.stop }

  it "creates a stripe customer" do

    # This doesn't touch stripe's servers nor the internet!
    customer = Stripe::Customer.create({
      email: 'johnny@appleseed.com',
      card: 'void_card_token'
    })
    expect(customer.email).to eq('johnny@appleseed.com')
  end
end
```

## Mocking Errors

Tired of manually inputting fake credit card numbers to test against errors? Tire no more!

```ruby
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
```

You can also set your own custom Stripe error using `prepare_error`:

```ruby
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
```

### Built-In Card Errors

```ruby
StripeMock.prepare_card_error(:incorrect_number)
StripeMock.prepare_card_error(:invalid_number)
StripeMock.prepare_card_error(:invalid_expiry_month)
StripeMock.prepare_card_error(:invalid_expiry_year)
StripeMock.prepare_card_error(:invalid_cvc)
StripeMock.prepare_card_error(:expired_card)
StripeMock.prepare_card_error(:incorrect_cvc)
StripeMock.prepare_card_error(:card_declined)
StripeMock.prepare_card_error(:missing)
StripeMock.prepare_card_error(:processing_error)
```

You can see the details of each error in [lib/stripe_mock/api/errors.rb](lib/stripe_mock/api/errors.rb)

## Running the Mock Server

Sometimes you want your test stripe data to persist for a bit, such as during integration tests
running on different processes. In such cases you'll want to start the stripe mock server:

    $ stripe-mock-server # Default port is 4999
    $ stripe-mock-server -p 4000
    $ stripe-mock-server --help

Then, instead of `StripeMock.start`, you'll want to use `StripeMock.start_client`:

```ruby
describe MyApp do
  before do
    @client = StripeMock.start_client
  end

  after do
    StripeMock.stop_client
    #
    # Alternatively:
    #
    # @client.close!
    # StripeMock.stop_client(:clear_server_data => true)
  end
end
```

This is all essentially the same as using `StripeMock.start`, except that the stripe test
data is held in its own server process.

Here are some other neat things you can do with the client:

```ruby
@client.state #=> 'ready'

@client.set_server_debug(true)
@client.get_server_data(:customers) # Also works for :charges, :plans, etc.
@client.clear_server_data

@client.close!
@client.state #=> 'closed'
```

## TODO

* Cover all stripe urls/methods
* Create hash for storing/retrieving all stripe objects in-memory
  * Currently implemented for: **Customers**, **Charges**, and **Plans**
* Throw useful errors that emulate Stripe's
  * For example: "You must supply either a card or a customer id" for `Stripe::Charge`

## Copyright

Copyright (c) 2013 Gilbert

See LICENSE.txt for details.
