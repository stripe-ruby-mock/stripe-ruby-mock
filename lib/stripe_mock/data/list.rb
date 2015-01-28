module StripeMock
  module Data
    class List
      attr_reader :data, :limit, :offset, :starting_after

      def initialize(data, options = {})
        @data = Array(data.clone)
        @limit = [[options[:limit] || 10, 100].min, 1].max # restrict @limit to 1..100
        @starting_after = options[:starting_after]
      end

      def url
        "/v1/#{object_types}"
      end

      def to_hash
        { object: "list", data: data_page, url: url, has_more: has_more? }
      end
      alias_method :to_h, :to_hash

      def has_more?
        (offset + limit) < data.size
      end

      def method_missing(method_name, *args, &block)
        hash = to_hash

        if hash.keys.include?(method_name)
          hash[method_name]
        else
          super
        end
      end

      def respond_to?(method_name, priv = false)
        to_hash.keys.include?(method_name) || super
      end

      private

      def offset
        if starting_after
          if index = data.index { |datum| datum.id == starting_after }
            index + 1
          else
            raise "No such object id: #{starting_after}"
          end
        else
          0
        end
      end

      def data_page
        data[offset, limit]
      end

      def object_types
        if first_object = data[0]
          "#{first_object.class.to_s.split('::')[-1].downcase}s"
        end
      end
    end
  end
end
