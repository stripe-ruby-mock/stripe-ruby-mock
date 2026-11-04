module StripeMock
  module Compat
    # stripe < 13
    class Legacy < Base
      Response = Struct.new(:data)

      def target
        Stripe::StripeClient
      end

      def method_name
        :execute_request
      end

      def active_client
        target.active_client
      end

      def respond(body, request)
        [Response.new(body), request.api_key]
      end

      def empty_response(request)
        [{}, request.api_key]
      end
    end
  end
end
