module StripeMock
  module RequestHandlers
    module Events

      def Events.included(klass)
        klass.add_handler 'get /v1/events/(.*)', :retrieve_event
      end

      def retrieve_event(route, method_url, params, headers)
        route =~ method_url
        assert_existence :event, $1, events[$1]
      end

    end
  end
end
