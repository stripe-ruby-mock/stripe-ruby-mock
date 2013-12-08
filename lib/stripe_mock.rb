require 'ostruct'
require 'jimson-temp'
require 'dante'

require 'stripe'

require 'stripe_mock/version'
require 'stripe_mock/data'
require 'stripe_mock/util'
require 'stripe_mock/error_queue'

require 'stripe_mock/errors/stripe_mock_error'
require 'stripe_mock/errors/unsupported_request_error'
require 'stripe_mock/errors/uninitialized_instance_error'
require 'stripe_mock/errors/unstarted_state_error'
require 'stripe_mock/errors/server_timeout_error'
require 'stripe_mock/errors/closed_client_connection_error'

require 'stripe_mock/client'
require 'stripe_mock/server'

require 'stripe_mock/api/instance'
require 'stripe_mock/api/client'
require 'stripe_mock/api/server'
require 'stripe_mock/api/card_tokens'
require 'stripe_mock/api/bank_tokens'
require 'stripe_mock/api/errors'
require 'stripe_mock/api/webhooks'
require 'stripe_mock/api/strict'
require 'stripe_mock/api/debug'

require 'stripe_mock/request_handlers/charges.rb'
require 'stripe_mock/request_handlers/cards.rb'
require 'stripe_mock/request_handlers/customers.rb'
require 'stripe_mock/request_handlers/events.rb'
require 'stripe_mock/request_handlers/invoices.rb'
require 'stripe_mock/request_handlers/invoice_items.rb'
require 'stripe_mock/request_handlers/plans.rb'
require 'stripe_mock/request_handlers/recipients.rb'
require 'stripe_mock/instance'

module StripeMock

  lib_dir = File.expand_path(File.dirname(__FILE__), '../..')
  @webhook_fixture_path = './spec/fixtures/stripe_webhooks/'
  @webhook_fixture_fallback_path = File.join(lib_dir, 'stripe_mock/webhook_fixtures')

  class << self
    attr_accessor :webhook_fixture_path
  end
end
