module StripeMock
  module RequestHandlers
    module Checkout
      module Session
        def Session.included(klass)
          klass.add_handler 'post /v1/checkout/sessions', :new_session
          klass.add_handler 'get /v1/checkout/sessions', :list_checkout_sessions
          klass.add_handler 'get /v1/checkout/sessions/([^/]*)', :get_checkout_session
          klass.add_handler 'get /v1/checkout/sessions/([^/]*)/line_items', :list_line_items
        end

        def new_session(route, method_url, params, headers)
          id = params[:id] || new_id('cs')

          [:cancel_url, :success_url].each do |p|
            require_param(p) if params[p].nil? || params[p].empty?
          end

          line_items = nil
          if params[:line_items]
            line_items = params[:line_items].each_with_index.map do |line_item, i|
              throw Stripe::InvalidRequestError("Quantity is required. Add `quantity` to `line_items[#{i}]`") unless line_item[:quantity]
              unless line_item[:price] || line_item[:price_data] || (line_item[:amount] && line_item[:currency] && line_item[:name])
                throw Stripe::InvalidRequestError("Price or amount and currency is required. Add `price`, `price_data`, or `amount`, `currency` and `name` to `line_items[#{i}]`")
              end
              {
                id: new_id("li"),
                price: if line_item[:price]
                  line_item[:price]
                elsif line_item[:price_data]
                  new_price(nil, nil, line_item[:price_data], nil)[:id]
                else
                  new_price(nil, nil, {
                    unit_amount: line_item[:amount],
                    currency: line_item[:currency],
                    product_data: {
                      name: line_item[:name]
                    }
                  }, nil)[:id]
                end,
                quantity: line_item[:quantity]
              }
            end
          end

          amount = nil
          currency = nil
          if line_items
            amount = 0

            line_items.each do |line_item| 
              price = prices[line_item[:price]]

              if price.nil?
                raise StripeMock::StripeMockError.new("Price not found for ID: #{line_item[:price]}")
              end

              amount += (price[:unit_amount] * line_item[:quantity])
            end

            currency = prices[line_items.first[:price]][:currency]
          end

          payment_status = "unpaid"
          payment_intent = nil
          setup_intent = nil
          case params[:mode]
          when nil, "payment"
            params[:customer] ||= new_customer(nil, nil, {email: params[:customer_email]}, nil)[:id]
            require_param(:line_items) if params[:line_items].nil? || params[:line_items].empty?
            payment_intent = new_payment_intent(nil, nil, {
              amount: amount,
              currency: currency,
              customer: params[:customer],
              payment_method_options: params[:payment_method_options],
              payment_method_types: params[:payment_method_types]
            }.merge(params[:payment_intent_data] || {}), nil)[:id]
            checkout_session_line_items[id] = line_items
          when "setup"
            if !params[:line_items].nil? && !params[:line_items].empty?
              throw Stripe::InvalidRequestError.new("You cannot pass `line_items` in `setup` mode", :line_items, http_status: 400)
            end
            setup_intent = new_setup_intent(nil, nil, {
              customer: params[:customer],
              payment_method_options: params[:payment_method_options],
              payment_method_types: params[:payment_method_types]
            }.merge(params[:setup_intent_data] || {}), nil)[:id]
            payment_status = "no_payment_required"
          when "subscription"
            params[:customer] ||= new_customer(nil, nil, {email: params[:customer_email]}, nil)[:id]
            require_param(:line_items) if params[:line_items].nil? || params[:line_items].empty?
            checkout_session_line_items[id] = line_items
          else
            throw Stripe::InvalidRequestError.new("Invalid mode: must be one of payment, setup, or subscription", :mode, http_status: 400)
          end

          checkout_sessions[id] = {
            id: id,
            object: "checkout.session",
            allow_promotion_codes: nil,
            amount_subtotal: amount,
            amount_total: amount,
            automatic_tax: {
              enabled: false,
              status: nil
            },
            billing_address_collection: nil,
            cancel_url: params[:cancel_url],
            client_reference_id: nil,
            currency: currency,
            customer: params[:customer],
            customer_details: nil,
            customer_email: params[:customer_email],
            livemode: false,
            locale: nil,
            metadata: params[:metadata],
            mode: params[:mode],
            payment_intent: payment_intent,
            payment_method_options: params[:payment_method_options],
            payment_method_types: params[:payment_method_types],
            payment_status: payment_status,
            setup_intent: setup_intent,
            shipping: nil,
            shipping_address_collection: nil,
            submit_type: nil,
            subscription: nil,
            success_url: params[:success_url],
            total_details: nil,
            url: URI.join(StripeMock.checkout_base, id).to_s
          }
        end

        def list_checkout_sessions(route, method_url, params, headers)
          Data.mock_list_object(checkout_sessions.values)
        end

        def get_checkout_session(route, method_url, params, headers)
          route =~ method_url
          checkout_session = assert_existence :checkout_session, $1, checkout_sessions[$1]

          checkout_session = checkout_session.clone
          if params[:expand]&.include?('setup_intent') && checkout_session[:setup_intent]
            checkout_session[:setup_intent] = setup_intents[checkout_session[:setup_intent]]
          end
          checkout_session
        end

        def list_line_items(route, method_url, params, headers)
          route =~ method_url
          checkout_session = assert_existence :checkout_session, $1, checkout_sessions[$1]

          case checkout_session[:mode]
          when "payment", "subscription"
            line_items = assert_existence :checkout_session_line_items, $1, checkout_session_line_items[$1]
            line_items.map do |line_item|
              price = prices[line_item[:price]].clone

              if price.nil?
                raise StripeMock::StripeMockError.new("Price not found for ID: #{line_item[:price]}")
              end

              {
                id: line_item[:id],
                object: "item",
                amount_subtotal: price[:unit_amount] * line_item[:quantity],
                amount_total: price[:unit_amount] * line_item[:quantity],
                currency: price[:currency],
                price: price.clone,
                quantity: line_item[:quantity]
              }
            end
          else
            throw Stripe::InvalidRequestError("Only payment and subscription sessions have line items")
          end
        end
      end
    end
  end
end
