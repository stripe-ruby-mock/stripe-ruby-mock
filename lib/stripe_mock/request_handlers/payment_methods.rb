module StripeMock
  module RequestHandlers
    module PaymentMethods
      ALLOWED_PARAMS = [:customer, :type]

      def PaymentMethods.included(klass)
        klass.add_handler 'post /v1/payment_methods',                 :new_payment_method
        klass.add_handler 'get /v1/payment_methods',                  :get_payment_methods
        klass.add_handler 'get /v1/payment_methods/(.*)',             :get_payment_method
        klass.add_handler 'post /v1/payment_methods/(.*)/attach',     :attach_payment_method
        klass.add_handler 'post /v1/payment_methods/(.*)/detach',     :detach_payment_method
      end

      def new_payment_method(route, method_url, params, headers)
        id = new_id('pm')

        payment_methods[id] = Data.mock_payment_method(
            params.merge(
                id: id
            )
        )

        payment_methods[id].clone
      end

      #
      # params: {:type=>"card", :customer=>"test_cus_3"}
      #
      def get_payment_methods(route, method_url, params, headers)
        params[:offset] ||= 0
        params[:limit] ||= 10

        clone = payment_methods.clone


        Data.mock_list_object(clone.values, params)
      end

      #
      # params: {:customer=>"test_cus_3"}
      #
      def attach_payment_method(route, method_url, params, headers)
        route =~ method_url
        id = $1
        payment_methods[id].merge!(params)
        payment_methods[id].clone
      end

      def detach_payment_method(route, method_url, params, headers)

      end

      def get_payment_method(route, method_url, params, headers)
        route =~ method_url
        id = $1
        assert_existence(:payment_method, $1, payment_methods[id])
      end

    end
  end
end
