module StripeMock
  module RequestHandlers
    module Helpers

      def generate_bank_token(bank_params)
        token = new_id 'btok'
        @bank_tokens[token] = Data.mock_bank_account bank_params
        token
      end

      def generate_card_token(card_params)
        token = new_id 'tok'
        card_params[:id] = new_id 'cc'
        @card_tokens[token] = Data.mock_card symbolize_names(card_params)
        token
      end

      def get_bank_by_token(token)
        if token.nil? || @bank_tokens[token].nil?
          Data.mock_bank_account
        else
          @bank_tokens.delete(token)
        end
      end

      def get_card_by_token(token)
        if token.nil? || @card_tokens[token].nil?
          # TODO: Make this strict
          msg = "Invalid token id: #{token}"
          raise Stripe::InvalidRequestError.new(msg, 'tok', 404)
        else
          @card_tokens.delete(token)
        end
      end

    end
  end
end