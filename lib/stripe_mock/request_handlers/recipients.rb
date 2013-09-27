module StripeMock
  module RequestHandlers
    module Recipients

      def Recipients.included(klass)
        klass.add_handler 'post /v1/recipients',            :new_recipient
        klass.add_handler 'get /v1/recipients/(.*)',        :get_recipient
      end

      def new_recipient(route, method_url, params, headers)
        id = new_id('rp')
        if params[:bank_account]
          params[:active_account] = get_bank_by_token(params.delete(:bank_account))
        end
        recipients[id] = Data.mock_recipient(params.merge :id => id)
        recipients[id]
      end

      def get_recipient(route, method_url, params, headers)
        route =~ method_url
        assert_existance :recipient, $1, recipients[$1]
        recipients[$1] ||= Data.mock_recipient(:id => $1)
      end
    end
  end
end
