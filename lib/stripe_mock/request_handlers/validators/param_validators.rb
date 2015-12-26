module StripeMock
  module RequestHandlers
    module ParamValidators

      def validate_create_plan_params(params)
        params[:id] = params[:id].to_s

        @base_strategy.create_plan_params.keys.each do |name|
          raise Stripe::InvalidRequestError.new("Missing required param: #{name}.", name) if params[name].nil?
        end
        if plans[ params[:id] ]
          raise Stripe::InvalidRequestError.new("Plan already exists.", :id)
        end
      end

    end
  end
end
