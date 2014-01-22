module StripeMock
  module RequestHandlers
    module Account

      def Account.included(klass)
        klass.add_handler 'get /v1/account',  :get_account
      end

      def get_account(route, method_url, params, headers)
        route =~ method_url
        assert_existance :account, $1, account
        account ||= Data.mock_account
      end

    end
  end
end