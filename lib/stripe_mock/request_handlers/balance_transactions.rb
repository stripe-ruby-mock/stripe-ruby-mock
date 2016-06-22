module StripeMock
  module RequestHandlers
    module BalanceTransactions

      def BalanceTransactions.included(klass)
        klass.add_handler 'get /v1/balance/history/(.*)',  :get_balance_transaction
        klass.add_handler 'get /v1/balance/history',       :list_balance_transactions
      end

      def get_balance_transaction(route, method_url, params, headers)
        route =~ method_url
        assert_existence :balance_transaction, $1, balance_transactions[$1]
      end

      def list_balance_transactions(route, method_url, params, headers)
        Data.mock_list_object(balance_transactions.values, params)
      end

    end
  end
end
