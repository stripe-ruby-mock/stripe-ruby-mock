module StripeMock
  module Compat
    class Base
      Request = Struct.new(:method, :url, :params, :headers, :api_key, :opts, keyword_init: true)

      def target
        raise NotImplementedError
      end

      def method_name
        raise NotImplementedError
      end

      def active_client
        raise NotImplementedError
      end

      def respond(body, request)
        raise NotImplementedError
      end

      def empty_response(request)
        raise NotImplementedError
      end

      def requestor
        @requestor ||= target.new
      end

      # The legacy `(method, url, api_key:, params:, headers:)` form is accepted on
      # every version, since it is also used to call Instance#mock_request directly.
      def parse(args, kwargs)
        raise ArgumentError, "Invalid arguments for mock_request" unless legacy_args?(args, kwargs)

        method, url = args
        Request.new(
          method: method,
          url: url,
          params: kwargs[:params] || {},
          headers: kwargs[:headers] || {},
          api_key: kwargs[:api_key]
        )
      end

      def route(args, kwargs)
        raise ArgumentError, "Invalid arguments for mock_request" unless legacy_args?(args, kwargs)

        args.first(2)
      end

      private

      def legacy_args?(args, kwargs)
        args.length == 2 && kwargs.key?(:api_key)
      end
    end
  end
end
