module StripeMock
  module RequestHandlers
    module Helpers
      BASIL = "2025-03-31".freeze

      def api_version(headers)
        (headers && headers[:stripe_version]) || Stripe.api_version
      end

      def basil_api?(headers)
        version = api_version(headers)
        !version.nil? && version.to_s >= BASIL
      end
    end
  end
end
