module StripeMock
  module RequestHandlers
    module Events

      def Events.included(klass)
        klass.add_handler 'get /v1/events/(.*)', :retrieve_event
      end

      def retrieve_event(route, method_url, params, headers)
        route =~ method_url
        event = events[$1]
        assert_existance :event, $1, event
        event
      end

    end
  end
end
