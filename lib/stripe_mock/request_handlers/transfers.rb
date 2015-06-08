module StripeMock
  module RequestHandlers
    module Transfers

      def Transfers.included(klass)
        klass.add_handler 'post /v1/transfers',             :new_transfer
        klass.add_handler 'get /v1/transfers',              :get_all_transfers
        klass.add_handler 'get /v1/transfers/(.*)',         :get_transfer
        klass.add_handler 'post /v1/transfers/(.*)/cancel', :cancel_transfer
      end

      def get_all_transfers(route, method_url, params, headers)
        if recipient = params[:recipient]
          assert_existence :recipient, recipient, recipients[recipient]
        end

        _transfers = transfers.each_with_object([]) do |(_, transfer), array|
          if recipient
            array << transfer if transfer[:recipient] == recipient
          else
            array << transfer
          end
        end

        if params[:limit]
          _transfers = _transfers.first([params[:limit], _transfers.size].min)
        end

        _transfers
      end

      def new_transfer(route, method_url, params, headers)
        id = new_id('tr')
        if params[:bank_account]
          params[:account] = get_bank_by_token(params.delete(:bank_account))
        end

        unless params[:amount].is_a?(Integer) || (params[:amount].is_a?(String) && /^\d+$/.match(params[:amount]))
          raise Stripe::InvalidRequestError.new("Invalid integer: #{params[:amount]}", 'amount', 400)
        end

        transfers[id] = Data.mock_transfer(params.merge :id => id)
      end

      def get_transfer(route, method_url, params, headers)
        route =~ method_url
        assert_existence :transfer, $1, transfers[$1]
        transfers[$1] ||= Data.mock_transfer(:id => $1)
      end

      def cancel_transfer(route, method_url, params, headers)
        route =~ method_url
        assert_existence :transfer, $1, transfers[$1]
        t = transfers[$1] ||= Data.mock_transfer(:id => $1)
        t.merge!({:status => "canceled"})
      end
    end
  end
end
