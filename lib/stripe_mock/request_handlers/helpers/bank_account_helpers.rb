module StripeMock
  module RequestHandlers
    module Helpers
      def verify_bank_account(object, bank_account_id, class_name='Customer')
        bank_accounts = object[:external_accounts] || object[:bank_accounts] || object[:sources]
        bank_account = bank_accounts[:data].find{|acc| acc[:id] == bank_account_id }
        return if bank_account.nil?
        bank_account['status'] = 'verified'
        bank_account
      end

      def get_bank_account(object, bank_account_id, class_name='Customer')
        bank_account = object[:bank_accounts][:data].find{|cc| cc[:id] == bank_account_id }
        if bank_account.nil?
          msg = "#{class_name} #{object[:id]} does not have bank_account #{bank_account_id}"
          raise Stripe::InvalidRequestError.new(msg, 'bank_account', 404)
        end
        bank_account
      end

      def add_bank_account_to_object(type, bank_account, object, replace_current=false)
        bank_account[type] = object[:id]
        if replace_current
          object[:bank_accounts][:data].delete_if {|bank_account| bank_account[:id] == object[:default_bank_account]}
          object[:default_bank_account] = bank_account[:id]
        else
          object[:bank_accounts][:count] += 1
        end

        object[:default_bank_account] = bank_account[:id] unless object[:default_bank_account]
        object[:bank_accounts][:data] << bank_account

        bank_account
      end
    end
  end
end
