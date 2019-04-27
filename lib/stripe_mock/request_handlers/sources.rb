module StripeMock
  module RequestHandlers
    module Sources

      def Sources.included(klass)
        klass.add_handler 'get /v1/customers/(.*)/sources', :retrieve_sources
        klass.add_handler 'post /v1/customers/(.*)/sources', :create_source
        klass.add_handler 'post /v1/customers/(.*)/sources/(.*)/verify', :verify_source
        klass.add_handler 'get /v1/customers/(.*)/sources/(.*)', :retrieve_source
        klass.add_handler 'delete /v1/customers/(.*)/sources/(.*)', :delete_source
        klass.add_handler 'post /v1/customers/(.*)/sources/(.*)', :update_source
        klass.add_handler 'post /v1/sources', :create_platform_source
      end

      def create_source(route, method_url, params, headers)
        route =~ method_url
        add_source_to(:customer, $1, params, customers)
      end

      def create_platform_source(_route, _method_url, params, _headers)
        if params[:card]
          card_from_params(params[:card]).tap do |card|
            @card_tokens[card[:id]] = card
          end
        else
          card = get_card_by_token(params[:token])
          @card_tokens[card[:id]] = card

          card[:id]
        end
      end

      def retrieve_sources(route, method_url, params, headers)
        route =~ method_url
        retrieve_object_cards(:customer, $1, customers)
      end

      def retrieve_source(route, method_url, params, headers)
        route =~ method_url
        customer = assert_existence :customer, $1, customers[$1]

        assert_existence :card, $2, get_card(customer, $2)
      end

      def delete_source(route, method_url, params, headers)
        route =~ method_url
        delete_card_from(:customer, $1, $2, customers)
      end

      def update_source(route, method_url, params, headers)
        route =~ method_url
        customer = assert_existence :customer, $1, customers[$1]

        card = assert_existence :card, $2, get_card(customer, $2)
        card.merge!(params)
        card
      end

      def verify_source(route, method_url, params, headers)
        route =~ method_url
        customer = assert_existence :customer, $1, customers[$1]

        if params[:amounts] == [32, 45] || params[:verification_method] == 'skip'
          bank_account = assert_existence :bank_account, $2, verify_bank_account(customer, $2)
        else
          msg = "The verification amounts provided do not match"
          raise Stripe::InvalidRequestError.new(msg, 'amounts', http_status: 404)
        end

        bank_account
      end

    end
  end
end
