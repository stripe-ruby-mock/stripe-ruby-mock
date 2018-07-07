module StripeMock
  module RequestHandlers
    module BankAccounts

      def BankAccounts.included(klass)
        klass.add_handler 'get /v1/customers/(.*)/bank_accounts', :retrieve_bank_accounts
        klass.add_handler 'post /v1/customers/(.*)/bank_accounts', :create_bank_account
        klass.add_handler 'get /v1/customers/(.*)/bank_accounts/(.*)', :retrieve_bank_account
        klass.add_handler 'delete /v1/customers/(.*)/bank_accounts/(.*)', :delete_bank_account
        klass.add_handler 'post /v1/customers/(.*)/bank_accounts/(.*)', :update_bank_account
        klass.add_handler 'get /v1/recipients/(.*)/bank_accounts/(.*)', :retrieve_recipient_bank_account
      end

      def create_bank_account(route, method_url, params, headers)
        route =~ method_url
        customer = assert_existance :customer, $1, customers[$1]

        bank_account = bank_account_from_params(params[:bank_account])
        add_bank_account_to_object(:customer, bank_account, customer)
      end

      def retrieve_bank_accounts(route, method_url, params, headers)
        route =~ method_url
        customer = assert_existance :customer, $1, customers[$1]

        bank_accounts = customer[:bank_accounts]
        bank_accounts[:count] = bank_accounts[:data].length
        bank_accounts
      end

      def retrieve_bank_account(route, method_url, params, headers)
        route =~ method_url
        customer = assert_existance :customer, $1, customers[$1]

        assert_existance :bank_account, $2, get_bank_account(customer, $2)
      end

      def retrieve_recipient_bank_account(route, method_url, params, headers)
        route =~ method_url
        recipient = assert_existance :recipient, $1, recipients[$1]

        assert_existance :bank_account, $2, get_bank_account(recipient, $2, "Recipient")
      end

      def delete_bank_account(route, method_url, params, headers)
        route =~ method_url
        customer = assert_existance :customer, $1, customers[$1]

        assert_existance :bank_account, $2, get_bank_account(customer, $2)

        bank_account = { id: $2, deleted: true }
        customer[:bank_accounts][:data].reject!{|cc|
          cc[:id] == bank_account[:id]
        }
        customer[:default_bank_account] = customer[:bank_accounts][:data].count > 0 ? customer[:bank_accounts][:data].first[:id] : nil
        bank_account
      end

      def update_bank_account(route, method_url, params, headers)
        route =~ method_url
        customer = assert_existance :customer, $1, customers[$1]

        bank_account = assert_existance :bank_account, $2, get_bank_account(customer, $2)
        bank_account.merge!(params)
        bank_account
      end

      private

      def bank_account_from_params(attrs_or_token)
        if attrs_or_token.is_a? Hash
          attrs_or_token = generate_bank_token(attrs_or_token)
        end
        bank_account = get_bank_by_token(attrs_or_token)
      end
    end
  end
end
