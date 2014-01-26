module StripeMock
  module RequestHandlers
    module Tokens

      def Tokens.included(klass)
        klass.add_handler 'post /v1/tokens',      :create_token
        klass.add_handler 'get /v1/tokens/(.*)',  :get_token
      end

      def create_token(route, method_url, params, headers)
        # "Sanitize" card number
        params[:card][:last4] = params[:card][:number][-4,4]
        token_id = generate_card_token(params[:card])
        card = @card_tokens[token_id]

        Data.mock_token(params.merge :id => token_id, :card => card)
      end

      def get_token(route, method_url, params, headers)
        route =~ method_url
        # A Stripe token can be either a bank token or a card token
        bank_or_card = @bank_tokens[$1] || @card_tokens[$1]
        assert_existance :token, $1, bank_or_card

        if bank_or_card[:object] == 'card'
          Data.mock_token(:id => $1, :card => bank_or_card)
        elsif bank_or_card[:object] == 'bank_account'
          Data.mock_token(:id => $1, :bank_account => bank_or_card)
        end
      end
    end
  end
end