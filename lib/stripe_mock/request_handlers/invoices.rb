module StripeMock
  module RequestHandlers
    module Invoices

      def Invoices.included(klass)
        klass.add_handler 'post /v1/invoices',               :new_invoice
        klass.add_handler 'get /v1/invoices',                :get_invoices
        klass.add_handler 'get /v1/invoices/(.*)',           :get_invoice
      end

      def new_invoice(route, method_url, params, headers)
        id = new_id('in')
        invoices[id] = Data.mock_invoice(params.merge :id => id)
      end

      def get_invoices(route, method_url, params, headers)
        params[:offset] ||= 0
        params[:count] ||= 10

        clone = invoices.clone

        if params[:customer]
          clone.delete_if { |k,v| v[:customer] != params[:customer] }
        end

        clone.values[params[:offset], params[:count]]
      end

      def get_invoice(route, method_url, params, headers)
        route =~ method_url
        assert_existance :invoice, $1, invoices[$1]
        invoices[$1] ||= Data.mock_invoice(:id => $1)
      end

    end
  end
end
