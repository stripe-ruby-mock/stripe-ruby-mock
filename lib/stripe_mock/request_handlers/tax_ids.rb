module StripeMock
  module RequestHandlers
    module TaxIds
      def TaxIds.included(klass)
        klass.add_handler 'post /v1/tax_ids', :new_tax_id
        klass.add_handler 'post /v1/customers/(.*)/tax_ids', :new_customer_tax_id
        klass.add_handler 'get /v1/tax_ids/([^/]*)', :get_tax_id
        klass.add_handler 'get /v1/customers/(.*)/tax_ids/([^/]*)', :get_customer_tax_id
        klass.add_handler 'get /v1/tax_ids', :list_tax_ids
        klass.add_handler 'get /v1/customers/(.*)/tax_ids', :list_customer_tax_ids
        klass.add_handler 'delete /v1/tax_ids/([^/]*)', :delete_tax_id
        klass.add_handler 'delete /v1/customers/(.*)/tax_ids/([^/]*)', :delete_customer_tax_id
      end

      def new_tax_id(route, method_url, params, headers)
        params[:id] ||= new_id('txi')
        tax_ids[ params[:id] ] = Data.mock_tax_id(params)
        tax_ids[ params[:id] ]
      end
      def new_customer_tax_id(route, method_url, params, headers)
        new_tax_id(route, method_url, params.merge(customer: $1))
      end

      def get_tax_id(route, method_url, params, headers)
        route =~ method_url
        tax_id = assert_existence :tax_id, $1, tax_ids[$1]
        tax_id.clone
      end
      def get_customer_tax_id(route, method_url, params, headers)
        route =~ method_url
        tax_id = tax_ids[$2]
        tax_id = nil if tax_id[:customer] != $1
        tax_id = assert_existence :tax_id, $2, tax_id
        tax_id.clone
      end

      def list_tax_ids(route, method_url, params, headers)
        Data.mock_list_object(tax_ids.values, params)
      end
      def list_customer_tax_ids(route, method_url, params, headers)
        Data.mock_list_object(tax_ids.values.select { |t| t[:customer] == $1 }, params)
      end

      def delete_tax_id(route, method_url, params, headers)
        route =~ method_url
        assert_existence :tax_id, $1, tax_ids[$1]

        tax_ids[$1] = {
          id: tax_ids[$1][:id],
          deleted: true
        }
      end
      def delete_customer_tax_id(route, method_url, params, headers)
        route =~ method_url
        tax_id = tax_ids[$2]
        tax_id = nil if tax_id[:customer] != $1
        tax_id = assert_existence :tax_id, $2, tax_id

        tax_ids[$2] = {
          id: tax_ids[$2][:id],
          deleted: true
        }
      end
    end
  end
end
