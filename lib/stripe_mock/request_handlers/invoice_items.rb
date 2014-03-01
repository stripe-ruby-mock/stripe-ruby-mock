module StripeMock
  module RequestHandlers
    module InvoiceItems

      def InvoiceItems.included(klass)
        klass.add_handler 'post /v1/invoiceitems',  :new_invoice_item
      end

      def new_invoice_item(route, method_url, params, headers)
        Data.mock_invoice_item(params)
      end

    end
  end
end
