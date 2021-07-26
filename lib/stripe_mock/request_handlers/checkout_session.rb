module StripeMock
  module RequestHandlers
    module Checkout
      module Session
        def Session.included(klass)
          klass.add_handler 'post /v1/checkout/sessions', :new_session
          klass.add_handler 'get /v1/checkout/sessions/(.*)', :get_checkout_session
        end

        def new_session(route, method_url, params, headers)
          id = params[:id] || new_id('cs')

          [:cancel_url, :payment_method_types, :success_url].each do |p|
            require_param(p) if params[p].nil? || params[p].empty?
          end

          amount = params[:line_items]&.map { |line_item| line_item[:amount] }&.sum
          currency = params[:line_items]&.first&.[](:currency)

          payment_status = "unpaid"
          payment_intent = nil
          setup_intent = nil
          case params[:mode]
          when nil, "payment"
            require_params(:line_items) if params[:line_items].nil? || params[:line_items].empty?
            payment_intent = new_payment_intent(nil, nil, {
              amount: amount,
              currency: currency,
              customer: params[:customer],
              line_items: params[:line_items],
              payment_method_options: params[:payment_method_options],
              payment_method_types: params[:payment_method_types]
            }.merge(params[:payment_intent_data] || {}), nil)[:id]
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
            require_params(:line_items) if line_items.nil? || line_items.empty?
            # TODO: Stripe does not create the Subscription when creating the Session, add support for a way to create
            # a subscription using this session.
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
            cancel_url: "http://example.com/checkout/cancel?session_id={CHECKOUT_SESSION_ID}",
            client_reference_id: nil,
            currency: currency,
            customer: params[:customer],
            customer_details: nil,
            customer_email: nil,
            livemode: false,
            locale: nil,
            metadata: {},
            mode: "setup",
            payment_intent: payment_intent,
            payment_method_options: params[:payment_method_options],
            payment_method_types: params[:payment_method_types],
            payment_status: payment_status,
            setup_intent: setup_intent,
            shipping: nil,
            shipping_address_collection: nil,
            submit_type: nil,
            subscription: nil,
            success_url: "http://example.com/checkout/success?session_id={CHECKOUT_SESSION_ID}",
            total_details: nil,
            url: "https://checkout.stripe.com/pay/#{id}"
          }
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
      end
    end
  end
end
