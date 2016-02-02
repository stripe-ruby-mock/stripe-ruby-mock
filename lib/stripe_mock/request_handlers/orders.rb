module StripeMock
  module RequestHandlers
    module Orders

      def Orders.included(klass)
        klass.add_handler 'post /v1/orders',                     :new_order
        klass.add_handler 'post /v1/orders/(.*)/pay',            :pay_order
        klass.add_handler 'post /v1/orders/(.*)',                :update_order
        klass.add_handler 'get /v1/orders/(.*)',                 :get_order
        klass.add_handler 'get /v1/orders',                      :list_orders
      end

      def new_order(route, method_url, params, headers)
        params[:id] ||= new_id('or')
        order_items = []

        unless params[:currency].to_s.size == 3
          raise Stripe::InvalidRequestError.new('You must supply a currency', nil, 400)
        end

        if params[:items]
          unless params[:items].is_a? Array
            raise Stripe::InvalidRequestError.new('You must supply a list of items', nil, 400)
          end

          unless params[:items].first.is_a? Hash
            raise Stripe::InvalidRequestError.new('You must supply an item', nil, 400)
          end
        end

        orders[ params[:id] ] = Data.mock_order(order_items, params)

        orders[ params[:id] ]
      end

      def update_order(route, method_url, params, headers)
        route =~ method_url
        order = assert_existence :order, $1, orders[$1]

        if params[:metadata]
          if params[:metadata].empty?
            order[:metadata] = {}
          else
            order[:metadata].merge(params[:metadata])
          end
        end

        if [:created, :paid, :canceled, :fulfilled, :returned].includes? params[:status]
          order[:status] = params[:status]
        end
        order
      end

      def get_order(route, method_url, params, headers)
        route =~ method_url
        assert_existence :order, $1, orders[$1]
      end

      def pay_order(route, method_url, params, headers)
        route =~ method_url
        order = assert_existence :order, $1, orders[$1]

        if params[:source].blank? && params[:customer].blank?
          raise Stripe::InvalidRequestError.new('You must supply a source or customer', nil, 400)
        end

        charge_id = new_id('ch')
        charges[charge_id] = Data.mock_charge(id: charge_id)
        order[:charge] = charge_id
        order[:status] = "paid"
        order
      end

      def list_orders(route, method_url, params, headers)
        Data.mock_list_object(orders.values, params)
      end

    end
  end
end
