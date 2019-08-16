module StripeMock
  module RequestHandlers
    module ParamValidators

      def validate_create_plan_params(params)
        params[:id] = params[:id].to_s

        @base_strategy.create_plan_params.keys.each do |name|
          message =
            if name == :amount
              "Plans require an `#{name}` parameter to be set."
            else
              "Missing required param: #{name}."
            end
          raise Stripe::InvalidRequestError.new(message, name) if params[name].nil?
        end

        if plans[ params[:id] ]
          raise Stripe::InvalidRequestError.new("Plan already exists.", :id)
        end

        unless params[:amount].integer?
          raise Stripe::InvalidRequestError.new("Invalid integer: #{params[:amount]}", :amount)
        end
      end

      def require_param(param_name)
        raise Stripe::InvalidRequestError.new("Missing required param: #{param_name}.", param_name.to_s, http_status: 400)
      end
    end
  end
end
