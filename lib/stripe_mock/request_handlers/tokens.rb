module StripeMock
  module RequestHandlers
    module Tokens

      def Tokens.included(klass)
        klass.add_handler 'post /v1/tokens', :create_token
      end

      def create_token(route, method_url, params, headers)
        card = Data.mock_card(params[:card].merge(last4: params[:card][:number][-4,4], customer: nil))
        id = generate_card_token(card)
        Data.mock_token(:id => id, :card => card)
      end

    end
  end
end