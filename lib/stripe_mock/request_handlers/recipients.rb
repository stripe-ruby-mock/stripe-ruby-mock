module StripeMock
  module RequestHandlers
    module Recipients

      def Recipients.included(klass)
        klass.add_handler 'post /v1/recipients',            :new_recipient
        klass.add_handler 'get /v1/recipients/(.*)',        :get_recipient
      end

      def new_recipient(route, method_url, params, headers)
        id = new_id('rp')
        recipients[id] = Data.mock_recipient(params.merge :id => id)
      end

      def get_recipient(route, method_url, params, headers)
        route =~ method_url
        assert_existance :recipient, $1, recipients[$1]
        recipients[$1] ||= Data.mock_recipient(:id => $1)
      end
    end
  end
end
