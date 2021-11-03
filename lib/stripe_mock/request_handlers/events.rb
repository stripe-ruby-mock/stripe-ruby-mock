module StripeMock
  module RequestHandlers
    module Events

      def Events.included(klass)
        klass.add_handler 'get /v1/events/(.*)', :retrieve_event
        klass.add_handler 'get /v1/events',      :list_events
      end

      def retrieve_event(route, method_url, params, headers)
        route =~ method_url
        assert_existence :event, $1, events[$1]
      end

      def list_events(route, method_url, params, headers)
        values = filter_by_created(events.values, params: params)
        Data.mock_list_object(values, params)
      end

      private

      def filter_by_created(event_list, params:)
        if params[:created].nil?
          return event_list
        end

        if params[:created].is_a?(Hash)
          if params[:created][:gt]
            event_list = event_list.select { |event| event[:created] > params[:created][:gt].to_i }
          end
          if params[:created][:gte]
            event_list = event_list.select { |event| event[:created] >= params[:created][:gte].to_i }
          end
          if params[:created][:lt]
            event_list = event_list.select { |event| event[:created] < params[:created][:lt].to_i }
          end
          if params[:created][:lte]
            event_list = event_list.select { |event| event[:created] <= params[:created][:lte].to_i }
          end
        else
          event_list = event_list.select { |event| event[:created] == params[:created].to_i }
        end
        event_list
      end

    end
  end
end
