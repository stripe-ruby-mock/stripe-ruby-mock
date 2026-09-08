module StripeMock
  module RequestHandlers
    module Helpers
      # Only supports exact matches on a single field, e.g.
      # - 'amount:100'
      # - 'email:"name@domain.com"'
      # - 'name:"Foo Bar"'
      # - 'metadata["foo"]:"bar"'
      QUERYSTRING_PATTERN = /\A(?<field>[\w\.]+)(\[['"](?<metadata_key>[^'"]*)['"]\])?:['"]?(?<value>[^'"]*)['"]?\z/
      def search_results(all_values, querystring, fields: [], resource_name:)
        values = all_values.dup
        query_match = QUERYSTRING_PATTERN.match(querystring)
        raise Stripe::InvalidRequestError.new(
          'We were unable to parse your search query.' \
            ' Try using the format `metadata["key"]:"value"` to query for metadata or key:"value" to query for other fields.',
          nil,
          http_status: 400,
        ) unless query_match

        case query_match[:field]
        when *fields
          values = values.select { |resource|
            exact_match?(actual: field_value(resource, field: query_match[:field]), expected: query_match[:value])
          }
        when "metadata"
          values = values.select { |resource|
            resource[:metadata] &&
              exact_match?(actual: resource[:metadata][query_match[:metadata_key].to_sym], expected: query_match[:value])
          }
        else
          raise Stripe::InvalidRequestError.new(
            "Field `#{query_match[:field]}` is an unsupported search field for resource `#{resource_name}`." \
              " See http://stripe.com/docs/search#query-fields-for-#{resource_name.gsub('_', '-')} for a list of supported fields.",
            nil,
            http_status: 400,
          )
        end

        values
      end

      def exact_match?(actual:, expected:)
        # allow comparisons of integers
        if actual.respond_to?(:to_i) && actual.to_i == actual
          expected = expected.to_i
        end
        # allow comparisons of boolean
        case expected
        when "true"
          expected = true
        when "false"
          expected = false
        end

        actual == expected
      end

      def field_value(resource, field:)
        value = resource
        field.split('.').each do |segment|
          value = value[segment.to_sym]
        end
        value
      end
    end
  end
end
