module StripeMock
  module RequestHandlers
    module Checkout
      def Checkout.included(klass)
        klass.add_handler 'post /v1/checkout/sessions', :new_session
      end

      def new_session(route, method_url, params, headers)
        if headers && headers[:idempotency_key]
          params[:idempotency_key] = headers[:idempotency_key]
          if checkout_sessions.any?
            original_checkout_session = checkout_sessions.values.find { |s| s[:idempotency_key] == headers[:idempotency_key]}
            return original_checkout_session if original_checkout_session
          end
        end

        params[:id] ||= new_id('cs')

        checkout_sessions[params[:id]] = Data.mock_checkout_session(params)
      end
    end
  end
end
