module StripeMock
  module Data
    class List
      attr_reader :data, :limit, :offset, :starting_after, :ending_before, :active

      def initialize(data, options = {})
        @data = Array(data.clone)
        @limit = [[options[:limit] || 10, 100].min, 1].max # restrict @limit to 1..100
        @starting_after = options[:starting_after]
        @ending_before  = options[:ending_before]
        @active = options[:active]
        if @data.first.is_a?(Hash) && @data.first[:created]
          @data.sort_by! { |x| x[:created] }
          @data.reverse!
        elsif @data.first.respond_to?(:created)
          @data.sort_by { |x| x.created }
          @data.reverse!
        end
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
        case
        when starting_after
          index = data.index { |datum| datum[:id] == starting_after }
          (index || raise("No such object id: #{starting_after}")) + 1
        when ending_before
          index = data.index { |datum| datum[:id] == ending_before }
          (index || raise("No such object id: #{ending_before}")) - 1
        else
          0
        end
      end

      def data_page
        filtered_data[offset, limit]
      end

      def filtered_data
        filtered_data = data
        filtered_data = filtered_data.select { |d| d[:active] == active } unless active.nil?

        filtered_data
      end

      def object_types
        if first_object = data[0]
          "#{first_object.class.to_s.split('::')[-1].downcase}s"
        end
      end
    end
  end
end
