# stripe-ruby-mock

* Homepage: https://github.com/mindeavor/stripe-ruby-mock
* Issues: https://github.com/mindeavor/stripe-ruby-mock/issues

## Install

In your gemfile:

    gem 'stripe-ruby-mock', '>= 1.8.4.4'

## Features

* No stripe server access required
* Easily test against stripe errors
* Mock and customize stripe webhooks

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

## Mocking Card Errors

Tired of manually inputting fake credit card numbers to test against errors? Tire no more!

```ruby
it "mocks a declined card error" do
  # Prepares an error for the next create charge request
  StripeMock.prepare_card_error(:card_declined)

  expect { Stripe::Charge.create }.to raise_error {|e|
    expect(e).to be_a Stripe::CardError
    expect(e.http_status).to eq(402)
    expect(e.code).to eq('card_declined')
  }
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

### Custom Errors

To raise an error on a specific type of request, take a look at the [request handlers folder](lib/stripe_mock/request_handlers/) and pass a method name to `StripeMock.prepare_error`.

If you wanted to raise an error for creating a new customer, for instance, you would do the following:

```ruby
it "raises a custom error for specific actions" do
  custom_error = StandardError.new("Please knock first.")

  StripeMock.prepare_error(custom_error, :new_customer)

  expect { Stripe::Charge.create }.to_not raise_error
  expect { Stripe::Customer.create }.to raise_error {|e|
    expect(e).to be_a StandardError
    expect(e.message).to eq("Please knock first.")
  }
end
```

In the above example, `:new_customer` is the name of a method from [customers.rb](lib/stripe_mock/request_handlers/customers.rb).

## Running the Mock Server

Sometimes you want your test stripe data to persist for a bit, such as during integration tests
running on different processes. In such cases you'll want to start the stripe mock server:

    # spec_helper.rb
    #
    # The mock server will automatically be killed when your tests are done running.
    #
    require 'thin'
    StripeMock.spawn_server

Then, instead of `StripeMock.start`, you'll want to use `StripeMock.start_client`:

```ruby
describe MyApp do
  before do
    @client = StripeMock.start_client
  end

  after do
    StripeMock.stop_client
    # Alternatively:
    #   @client.close!
    # -- Or --
    #   StripeMock.stop_client(:clear_server_data => true)
  end
end
```

This is all essentially the same as using `StripeMock.start`, except that the stripe test
data is held in its own server process.

Here are some other neat things you can do with the client:

```ruby
@client.state #=> 'ready'

@client.get_server_data(:customers) # Also works for :charges, :plans, etc.
@client.clear_server_data

@client.close!
@client.state #=> 'closed'
```

### Mock Server Options

```ruby
# NOTE: Shown below are the default options
StripeMock.default_server_pid_path = './stripe-mock-server.pid'

StripeMock.spawn_server(
  :pid_path => StripeMock.default_server_pid_path,
  :host => '0.0.0.0',
  :port => 4999,
  :server => :thin
)

StripeMock.kill_server(StripeMock.default_server_pid_path)
```

### Mock Server Command

If you need the mock server to continue running even after your tests are done,
you'll want to use the executable:

    $ stripe-mock-server -p 4000
    $ stripe-mock-server --help

## Mocking Webhooks

If your application handles stripe webhooks, you are most likely retrieving the event from
stripe and passing the result to a handler. StripeMock helps you by easily mocking that event:

```ruby
it "mocks a stripe webhook" do
  event = StripeMock.mock_webhook_event('customer.created')

  customer_object = event.data.object
  expect(customer_object.id).to_not be_nil
  expect(customer_object.active_card).to_not be_nil
  # etc.
end
```

### Customizing Webhooks

By default, StripeMock searches in your `spec/fixtures/stripe_webhooks/` folder for your own, custom webhooks.
If it finds nothing, it falls back to [test events generated through stripe's webhooktester](lib/stripe_mock/webhook_fixtures/).

You can name events whatever you like in your `spec/fixtures/stripe_webhooks/` folder. However, if you try to call a non-existant event that's not in that folder, StripeMock will throw an error.

If you wish to use a different fixture path, you can set it yourself:

    StripeMock.webhook_fixture_path = './spec/other/folder/'

Also, you can override values whenever you create any webhook event:

```ruby
it "can override default webhook values" do
  # NOTE: given hash values get merged directly into event.data.object
  event = StripeMock.mock_webhook_event('customer.created', {
    :id => 'cus_my_custom_value',
    :email => 'joe@example.com'
  })
  # Alternatively:
  # event.data.object.id = 'cus_my_custom_value'
  # event.data.object.email = 'joe@example.com'
  expect(event.data.object.id).to eq('cus_my_custom_value')
  expect(event.data.object.email).to eq('joe@example.com')
end
```

## Debugging

To enable debug messages:

    StripeMock.toggle_debug(true)

This will **only last for the session**; Once you call `StripeMock.stop` or `StripeMock.stop_client`,
debug will be toggled off.

If you always want debug to be on (it's quite verbose), you should put this in a `before` block.

## TODO

* Cover all stripe urls/methods
* Create hash for storing/retrieving all stripe objects in-memory
  * Currently implemented for: **Customers**, **Charges**, and **Plans**
* Throw useful errors that emulate Stripe's
  * For example: "You must supply either a card or a customer id" for `Stripe::Charge`

## Developing stripe-ruby-mock

To run the tests:

    $ rspec

Patches are welcome and greatly appreciated! If you're contributing to fix a problem,
be sure to write tests that illustrate the problem being fixed.
This will help ensure that the problem remains fixed in future updates.

## Copyright

Copyright (c) 2013 Gilbert

See LICENSE.txt for details.
