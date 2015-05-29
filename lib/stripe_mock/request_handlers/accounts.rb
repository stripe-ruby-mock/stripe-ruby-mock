module StripeMock
  module RequestHandlers
    module Accounts

      def Accounts.included(klass)
        klass.add_handler 'post /v1/accounts',  :new_account
        klass.add_handler 'get /v1/account',      :get_account
        klass.add_handler 'get /v1/accounts/(.*)',  :get_account
        klass.add_handler 'post /v1/accounts/(.*)',  :update_account
      end

      def new_account(route, method_url, params, headers)
        params[:id] ||= new_id('acct')
        route =~ method_url
        accounts[ params[:id] ] ||= Data.mock_account(params)
      end

      def get_account(route, method_url, params, headers)
        route =~ method_url
        if $1
          accounts[$1] || raise(Stripe::AuthenticationError.new('no', 401))
        else
          Data.mock_account
        end
      end

      def update_account(route, method_url, params, headers)
        route =~ method_url
        assert_existence :account, $1, accounts[$1]
        accounts[$1].merge!(params)
      end

    end
  end
end
