module StripeMock
  module RequestHandlers
    module PaymentMethods
      ALLOWED_PARAMS = [:description, :metadata, :receipt_email, :shipping, :destination, :payment_method, :payment_method_types, :setup_future_usage, :transfer_data, :amount, :currency]

      def PaymentMethods.included(klass)
        klass.add_handler 'post /v1/payment_methods',             :new_payment_method
        klass.add_handler 'get /v1/payment_methods/(.*)',         :retrive_payment_method
        klass.add_handler 'get /v1/payment_methods',              :list_payment_methods
        klass.add_handler 'post /v1/payment_methods/(.*)/attach', :attach_payment_method
        klass.add_handler 'post /v1/payment_methods/(.*)/detach', :detach_payment_method
        klass.add_handler 'post /v1/payment_methods/(.*)',        :update_payment_method
      end

      def new_payment_method(_route, _method_url, params, _headers)
        id = new_id('pm')

        ensure_payment_method_required_params(params)
        params[:card][:last4] = params[:card][:number][-4..-1].to_i if params[:card]
        payment_methods[id] = Data.mock_payment_method(params.merge(id: id))
        payment_methods[id]
      end

      def retrive_payment_method(route, method_url, _params, _headers)
        route =~ method_url

        assert_existence :payment_method, $1, payment_methods[$1]
      end

      def list_payment_methods(_route, _method_url, params, _headers)
        params[:offset] ||= 0
        params[:limit] ||= 10

        result = payment_methods.clone

        if params[:customer]
          result.delete_if { |_,v| v[:customer] != params[:customer] }
        end

        Data.mock_list_object(result.values, params)
      end

      def attach_payment_method(route, method_url, params, headers)
        route =~ method_url

        payment_method = assert_existence :payment_method, $1, payment_methods[$1]

        if params[:customer]
          customer = assert_existence :customer, params[:customer], customers[params[:customer]]
          payment_method[:customer] = customer[:id]
        end

        payment_method
      end

      def detach_payment_method(route, method_url, params, headers)
        route =~ method_url

        payment_method = assert_existence :payment_method, $1, payment_methods[$1]
        payment_method[:customer] = nil

        payment_method
      end

      def update_payment_method(route, method_url, params, headers)
        route =~ method_url

        payment_method = assert_existence :payment_method, $1, payment_methods[$1]

        if payment_method[:customer].nil?
          raise Stripe::InvalidRequestError.new('You must save this PaymentMethod to a customer before you can update it.', nil, http_status: 400)
        end

        payment_method.merge!(params.slice(:billing_details, :card, :metadata))
        payment_method
      end

      private

      def ensure_payment_method_required_params(params)
        require_param(:type) unless params[:type]
        require_param(:card) if params[:card].nil? && params[:type] == 'card'

        raise Stripe::InvalidRequestError.new('Invalid type: must be one of card or card_present', nil, http_status: 400) if invalid_type?(params[:type])
      end

      def invalid_type?(type)
        !%w[card card_present].include?(type)
      end
    end
  end
end
