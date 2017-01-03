module StripeMock
  module RequestHandlers
    module Accounts

      def Accounts.included(klass)
        klass.add_handler 'post /v1/accounts',      :new_account
        klass.add_handler 'get /v1/account',        :get_account
        klass.add_handler 'get /v1/accounts/(.*)',  :get_account
        klass.add_handler 'post /v1/accounts/(.*)', :update_account
        klass.add_handler 'get /v1/accounts',       :list_accounts
        klass.add_handler 'post /oauth/deauthorize',:deauthorize
      end

      def new_account(route, method_url, params, headers)
        params[:id] ||= new_id('acct')
        route =~ method_url
        accounts[params[:id]] ||= Data.mock_account(params)
      end

      def get_account(route, method_url, params, headers)
        route =~ method_url
        init_account
        id = $1 || accounts.keys[0]
        assert_existence :account, id, accounts[id]
      end

      def update_account(route, method_url, params, headers)
        route =~ method_url
        assert_existence :account, $1, accounts[$1]
        accounts[$1].merge!(params)
      end

      def list_accounts(route, method_url, params, headers)
        init_account
        Data.mock_list_object(accounts.values, params)
      end

      def deauthorize(route, method_url, params, headers)
        init_account
        route =~ method_url
        Stripe::StripeObject.construct_from(:stripe_user_id => params[:stripe_user_id])
      end

      private

      def init_account
        if accounts == {}
          acc = Data.mock_account
          accounts[acc[:id]] = acc
        end
      end
    end
  end
end
