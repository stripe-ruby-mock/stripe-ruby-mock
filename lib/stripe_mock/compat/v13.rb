module StripeMock
  module Compat
    # stripe >= 13
    class V13 < Base
      HEADERS = %w[request-id stripe-account-id stripe-version stripe-version-stabl idempotency-key content-type].freeze

      def client
        Stripe::APIRequestor
      end

      def method_name
        :execute_request_internal
      end

      def active_client
        client.active_requestor
      end

      def parse(args, kwargs)
        return super unless args.length == 6

        method, url, _base_address, params, opts, _usage = args
        requestor = active_client
        opts = Stripe::RequestOptions.merge_config_and_opts(requestor.config, opts)
        headers = requestor.send(:request_headers, method, Stripe::Util.get_api_mode(url), opts)
        Request.new(
          method: method,
          url: url,
          params: params,
          headers: headers.transform_keys { |key| Util.snake_case(key).to_sym },
          opts: opts
        )
      end

      def route(args, kwargs)
        return super unless args.length == 6

        args.first(2)
      end

      def pin_version(args, kwargs)
        return [args, kwargs] unless args.length == 6

        args = args.dup
        args[4] = { stripe_version: active_client.config.api_version }.merge(args[4] || {})
        [args, kwargs]
      end

      def respond(body, request)
        [http_response(body.to_json, request.headers.slice(*HEADERS)), request.opts]
      end

      def empty_response(request)
        [{}, request.opts]
      end

      private

      def http_response(body, headers, code: "200", message: "OK")
        response = Net::HTTPResponse::CODE_TO_OBJ[code].new("1.1", code, message)
        headers.each { |k, v| response[k] = v }
        response.instance_variable_set(:@body, body)
        response.instance_variable_set(:@read, true)
        response
      end
    end
  end
end
