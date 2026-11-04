require 'stripe_mock/compat/base'
require 'stripe_mock/compat/legacy'
require 'stripe_mock/compat/v13'

module StripeMock
  module Compat
    # Newest first; the first entry whose minimum version is met wins.
    ADAPTERS = [
      ['13.0.0', V13],
      ['0', Legacy]
    ].freeze

    def self.stripe_version
      Gem::Version.new(Stripe::VERSION)
    end

    def self.adapter
      @adapter ||= ADAPTERS.find { |min, _| stripe_version >= Gem::Version.new(min) }.last.new
    end

    def self.stripe_gte_13?
      stripe_version >= Gem::Version.new('13.0.0')
    end

    def self.method
      adapter.method_name
    end

    def self.client
      adapter.target
    end

    def self.client_instance
      adapter.requestor
    end

    def self.active_client
      adapter.active_client
    end
  end
end
