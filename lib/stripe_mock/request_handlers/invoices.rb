module StripeMock
  module RequestHandlers
    module Invoices

      def Invoices.included(klass)
        klass.add_handler 'post /v1/invoices',               :new_invoice
        klass.add_handler 'get /v1/invoices/(.*)',           :get_invoice
        klass.add_handler 'get /v1/invoices',                :list_invoices
      end

      def new_invoice(route, method_url, params, headers)
        id = new_id('in')
        invoices[id] = Data.mock_invoice(params.merge :id => id)
      end

      def list_invoices(route, method_url, params, headers)
        params[:offset] ||= 0
        params[:count] ||= 10

        result = invoices.clone

        if params[:customer]
          result.delete_if { |k,v| v[:customer] != params[:customer] }
        end

        result.values[params[:offset], params[:count]]
      end

      def get_invoice(route, method_url, params, headers)
        route =~ method_url
        assert_existance :invoice, $1, invoices[$1]
        invoices[$1] ||= Data.mock_invoice(:id => $1)
      end

    end
  end
end
