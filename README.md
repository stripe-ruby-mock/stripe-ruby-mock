# stripe-ruby-mock

* Homepage: https://github.com/mindeavor/stripe-ruby-mock
* Issues: https://github.com/mindeavor/stripe-ruby-mock/issues

## Install

    $ gem install stripe-ruby-mock

## Features

* No stripe server access required
* Easily test against stripe errors (soon)

## Description

** *WARNING: THIS LIBRARY IS INCOMPLETE* **

At its core, this library overrides [stripe-ruby's](https://github.com/stripe/stripe-ruby)
request method to skip all http calls and
instead directly return test data. This allows you to write and run tests
without the need to actually hit stripe's servers.

You can use stripe-ruby-mock with any ruby testing library. Here's a quick dummy example with RSpec:

    require 'stripe'
    require 'stripe_mock'

    describe MyApp do
      before { StripeMock.start }
      after { StripeMock.stop }

      it "should create a stripe customer" do

        # This doesn't touch stripe's servers nor the internet!
        customer = Stripe::Customer.create({
          email: 'johnny@appleseed.com',
          card: 'void_card_token'
        })
        expect(customer.email).to eq('johnny@appleseed.com')
      end
    end

## TODO

* Cover all stripe urls/methods
* Mock stripe error responses
* Create hash for storing/retrieving stripe objects in-memory
  * Currently implemented for: **Customers**

## Copyright

Copyright (c) 2013 Gilbert

See LICENSE.txt for details.
