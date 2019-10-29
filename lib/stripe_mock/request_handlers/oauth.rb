module StripeMock
  module RequestHandlers
    module OAuth
      def self.included(klass)
        klass.add_handler 'post /oauth/token', :generate_auth_token
      end

      def generate_auth_token(route, method_url, params, headers)
        if params[:code].starts_with?('ac_')
          account_id = new_id('acct')
          accounts[account_id] = Data.mock_account(id: account_id, type: 'express')

          Data.mock_account_creation_oauth_token(account_id: account_id)
        else
          {}
        end
      end
    end
  end
end
