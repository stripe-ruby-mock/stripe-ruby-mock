module StripeMock
  module RequestHandlers
    module Charges

      def Charges.included(klass)
        klass.add_handler 'post /v1/charges',               :new_charge
        klass.add_handler 'get /v1/charges/(.*)',           :get_charge
        klass.add_handler 'post /v1/charges/(.*)/capture',  :capture_charge
        klass.add_handler 'post /v1/recipients',            :new_recipient
        klass.add_handler 'get /v1/recipients/(.*)',        :get_recipient
      end

      def new_charge(route, method_url, params, headers)
        id = new_id('ch')
        charges[id] = Data.mock_charge(params.merge :id => id)
      end

      def get_charge(route, method_url, params, headers)
        route =~ method_url
        assert_existance :charge, $1, charges[$1]
        charges[$1] ||= Data.mock_charge(:id => $1)
      end

      def capture_charge(route, method_url, params, headers)
        route =~ method_url
        charge = charges[$1]
        assert_existance :charge, $1, charge

        charge[:captured] = true
        charge
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
