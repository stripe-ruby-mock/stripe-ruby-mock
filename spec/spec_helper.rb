require 'set'

gem 'rspec', '~> 2.4'
require 'rspec'
require 'stripe'
require 'stripe_mock'
require 'stripe_mock/server'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir["./spec/support/**/*.rb"].each {|f| require f}
