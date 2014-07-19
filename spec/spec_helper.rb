require 'set'

gem 'rspec', '~> 2.4'
require 'rspec'
require 'stripe'
require 'stripe_mock'
require 'stripe_mock/server'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir["./spec/support/**/*.rb"].each {|f| require f}

RSpec.configure do |c|

  if c.filter_manager.inclusions.keys.include?(:live)
    puts "Running **live** tests against Stripe..."
    StripeMock.set_default_test_helper_strategy(:live)
    c.filter_run_excluding :mock_server => true

    c.before(:each) do
      StripeMock.stub(:start).and_return(nil)
      StripeMock.stub(:stop).and_return(nil)
      Stripe.api_key = ENV['STRIPE_SECRET_KEY']
    end
    c.after(:each) { sleep 1 }
  end
end
