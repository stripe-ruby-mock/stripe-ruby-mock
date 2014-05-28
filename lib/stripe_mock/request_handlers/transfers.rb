module StripeMock
  module RequestHandlers
    module Transfers

      def Transfers.included(klass)
        klass.add_handler 'post /v1/transfers',             :new_transfer
        klass.add_handler 'get /v1/transfers/(.*)',         :get_transfer
        klass.add_handler 'post /v1/transfers/(.*)/cancel', :cancel_transfer
      end

      def new_transfer(route, method_url, params, headers)
        id = new_id('tr')
        if params[:bank_account]
          params[:account] = get_bank_by_token(params.delete(:bank_account))
        end
        transfers[id] = Data.mock_transfer(params.merge :id => id)
        transfers[id]
      end

      def get_transfer(route, method_url, params, headers)
        route =~ method_url
        assert_existance :transfer, $1, transfers[$1]
        transfers[$1] ||= Data.mock_transfer(:id => $1)
      end

      def cancel_transfer(route, method_url, params, headers)
        route =~ method_url
        assert_existance :transfer, $1, transfers[$1]
        t = transfers[$1] ||= Data.mock_transfer(:id => $1)
        t.merge!({:status => "canceled"})
      end
    end
  end
end
