module StripeMock
  module RequestHandlers
    module IssuingCardholders
      def IssuingCardholders.included(klass)
        klass.add_handler 'post /v1/issuing/cardholders', :new_cardholder
        klass.add_handler 'get /v1/issuing/cardholders/([^/]*)', :get_cardholder
        klass.add_handler 'post /v1/issuing/cardholders/([^/]*)', :update_cardholder
        klass.add_handler 'get /v1/issuing/cardholders', :list_cardholders
      end

      def new_cardholder(route, method_url, params, headers)
        params[:id] ||= new_id('ich')
        route =~ method_url
        ensure_cardholder_params(params)
        cardholders[params[:id]] ||= Data.mock_cardholder(params)
      end

      def get_cardholder(route, method_url, params, headers)
        route =~ method_url
        assert_existence :cardholder, $1, cardholders[$1]
      end

      def update_cardholder(route, method_url, params, headers)
        route =~ method_url
        cardholder = assert_existence :cardholder, $1, cardholders[$1]
        cardholder.merge!(params)
      end

      def list_cardholders(route, method_url, params, headers)
        Data.mock_list_object(cardholders.values, params)
      end

      private

      def ensure_cardholder_params(params)
        require_param(:type) unless params[:type]
        require_param(:name) unless params[:name]
        require_param(:billing) unless params[:billing]
        node = params[:billing][:address]
        require_param('billing[address]') unless node
        require_param('billing[address][line1]') unless node[:line1]
        require_param('billing[address][city]') unless node[:city]
        require_param('billing[address][country]') unless node[:country]
        require_param('billing[address][state]') unless node[:state]
        require_param('billing[address][postal_code]') unless node[:postal_code]
      end
    end
  end
end

