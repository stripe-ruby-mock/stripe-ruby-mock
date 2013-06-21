module StripeMock
  module RequestHandlers
    module Plans

      def Plans.included(klass)
        klass.add_handler 'post /v1/plans',     :new_plan
        klass.add_handler 'get /v1/plans/(.*)', :get_plan
        klass.add_handler 'get /v1/plans',      :list_plans
      end

      def new_plan(route, method_url, params, headers)
        params[:id] ||= new_id('plan')
        plans[ params[:id] ] = Data.test_plan(params)
      end

      def get_plan(route, method_url, params, headers)
        route =~ method_url
        plans[$1] ||= Data.test_plan(:id => $1)
      end

      def list_plans(route, method_url, params, headers)
        plans.values
      end

    end
  end
end
