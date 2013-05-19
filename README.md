# stripe-ruby-mock

* Homepage: https://github.com/mindeavor/stripe-ruby-mock
* Issues: https://github.com/mindeavor/stripe-ruby-mock/issues

## Install

    $ gem install stripe-ruby-mock

## Features

* No stripe server access required
* Easily test against stripe errors

## Description

** *WARNING: THIS LIBRARY IS INCOMPLETE* **

At its core, this library overrides [stripe-ruby's](https://github.com/stripe/stripe-ruby)
request method to skip all http calls and
instead directly return test data. This allows you to write and run tests
without the need to actually hit stripe's servers.

You can use stripe-ruby-mock with any ruby testing library. Here's a quick dummy example with RSpec:

```ruby
require 'stripe'
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

Tired of manually inputting fake credit card numbers to test against errors? Consider it a thing of the past!

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

## TODO

* Cover all stripe urls/methods
* Create hash for storing/retrieving all stripe objects in-memory
  * Currently implemented for: **Customers** and **Charges**

## Copyright

Copyright (c) 2013 Gilbert

See LICENSE.txt for details.
