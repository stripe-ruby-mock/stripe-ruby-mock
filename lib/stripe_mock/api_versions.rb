module StripeMock
  # Handlers store and return objects in one internal (pre-basil) shape.
  # Each Change reshapes responses, or maps request params, for API versions
  # on or after the version it applies to.
  module ApiVersions
    class Change
      class << self
        attr_reader :version, :objects, :handlers

        def applies_to(version, *objects)
          @version = version
          @objects = objects
          ApiVersions.register(self)
        end

        def params_for(*handlers)
          @handlers = handlers
        end

        # Fields the version dropped; deleted only when StripeMock.strict_api_version is set.
        def removes(*fields)
          @removed = fields
        end

        def removed
          @removed || []
        end
      end

      def response(object)
        object
      end

      def params(params)
        params
      end
    end

    @changes = []

    class << self
      attr_reader :changes

      def register(change)
        @changes << change
        @changes.sort_by!(&:version)
      end

      def version(headers = nil)
        from_headers = headers && (headers[:stripe_version] || headers["Stripe-Version"])
        from_headers || Stripe.api_version || (Stripe::ApiVersion::CURRENT if defined?(Stripe::ApiVersion))
      end

      def at_least?(date, headers = nil)
        current = version(headers)
        !current.nil? && current.to_s >= date
      end

      def params(handler, params, headers = nil)
        active(headers).each do |change|
          params = change.new.params(params) if change.handlers&.include?(handler)
        end
        params
      end

      def response(body, headers = nil)
        changes = active(headers).reject { |change| change.objects.empty? }
        return body if changes.empty?

        reshape(deep_dup(body), changes)
      end

      private

      def active(headers)
        current = version(headers)
        return [] if current.nil?

        @changes.select { |change| current.to_s >= change.version }
      end

      def reshape(value, changes)
        case value
        when Hash
          value.each_value { |child| reshape(child, changes) }
          matching = changes.select { |change| change.objects.include?(value[:object]) }
          matching.each { |change| change.new.response(value) }
          if StripeMock.strict_api_version
            matching.flat_map(&:removed).each { |field| value.delete(field) }
          end
        when Array
          value.each { |child| reshape(child, changes) }
        end
        value
      end

      def deep_dup(value)
        case value
        when Hash then value.each_with_object({}) { |(k, v), copy| copy[k] = deep_dup(v) }
        when Array then value.map { |v| deep_dup(v) }
        else value
        end
      end
    end
  end
end
