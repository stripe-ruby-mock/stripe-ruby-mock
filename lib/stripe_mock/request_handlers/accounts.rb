module StripeMock
  module RequestHandlers
    module Accounts

      def Accounts.included(klass)
        klass.add_handler 'post /v1/accounts',      :new_account
        klass.add_handler 'get /v1/account',        :get_account
        klass.add_handler 'get /v1/accounts/(.*)',  :get_account
        klass.add_handler 'post /v1/accounts/(.*)', :update_account
        klass.add_handler 'get /v1/accounts',       :list_accounts
      end

      def new_account(route, method_url, params, headers)
        params[:id] ||= new_id('acct')
        route =~ method_url
        binding.pry
        accounts[ params[:id] ] ||= Data.mock_account(params)
        accounts[ params[:id] ].merge({:bank_accounts => []})
      end

      def get_account(route, method_url, params, headers)
        route =~ method_url
        accounts[$1]
      end

      def update_account(route, method_url, params, headers)
        route =~ method_url
        assert_existence :account, $1, accounts[$1]
        accounts[$1].merge!(params)
      end

      def list_accounts(route, method_url, params, headers)
        binding.pry
        Data.mock_list_object(accounts.values, params)
      end
    end
  end
end
