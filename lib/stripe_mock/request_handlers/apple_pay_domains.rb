module StripeMock
  module RequestHandlers
    module ApplePayDomains

      def ApplePayDomains.included(klass)
        klass.add_handler 'post /v1/apple_pay/domains', :new_domain
        klass.add_handler 'get /v1/apple_pay/domains/(.*)', :get_domain
        klass.add_handler 'delete /v1/apple_pay/domains/(.*)', :delete_domain
        klass.add_handler 'get /v1/apple_pay/domains', :list_domains
      end

      def new_domain(route, method_url, params, headers)
        params[:id] ||= new_id('domain')
        raise Stripe::InvalidRequestError.new('Missing required param: domain_name', 'apple_pay_domain', http_status: 400) unless params[:domain_name]
        apple_pay_domains[ params[:id] ] = Data.mock_apple_pay_domain.merge(params)
      end

      def get_domain(route, method_url, params, headers)
        route =~ method_url
        assert_existence :apple_pay_domain, $1, apple_pay_domains[$1]
      end

      def delete_domain(route, method_url, params, headers)
        route =~ method_url
        assert_existence :apple_pay_domain, $1, apple_pay_domains[$1].delete($1)
      end

      def list_domains(route, method_url, params, headers)
        Data.mock_list_object(apple_pay_domains.values, params)
      end
    end
  end
end