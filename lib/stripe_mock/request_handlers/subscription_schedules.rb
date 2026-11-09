module StripeMock
  module RequestHandlers
    module SubscriptionSchedules

      def SubscriptionSchedules.included(klass)
        klass.add_handler 'post /v1/subscription_schedules',                   :new_subscription_schedule
        klass.add_handler 'get /v1/subscription_schedules',                    :list_subscription_schedules
        klass.add_handler 'get /v1/subscription_schedules/([^/]*)',            :get_subscription_schedule
        klass.add_handler 'post /v1/subscription_schedules/([^/]*)/cancel',    :cancel_subscription_schedule
        klass.add_handler 'post /v1/subscription_schedules/([^/]*)/release',   :release_subscription_schedule
        klass.add_handler 'post /v1/subscription_schedules/([^/]*)',           :update_subscription_schedule
      end

      SCHEDULE_CREATE_PARAMS = %i(customer from_subscription start_date end_behavior phases metadata default_settings expand).freeze
      SCHEDULE_UPDATE_PARAMS = %i(end_behavior phases metadata default_settings proration_behavior expand).freeze
      SCHEDULE_PHASE_PARAMS = %i(items iterations end_date start_date trial_end trial coupon metadata default_payment_method
                                 collection_method proration_behavior description currency default_tax_rates billing_cycle_anchor).freeze
      SCHEDULE_END_BEHAVIORS = %w(release cancel).freeze
      SCHEDULE_MUTABLE_STATUSES = %w(not_started active).freeze

      def new_subscription_schedule(route, method_url, params, headers)
        stripe_account = headers && headers[:stripe_account] || Stripe.api_key
        reject_unknown_schedule_params(params, SCHEDULE_CREATE_PARAMS)
        validate_schedule_end_behavior(params[:end_behavior])

        if params[:from_subscription]
          return schedule_from_subscription(params, stripe_account)
        end

        require_param(:customer) unless params[:customer]
        customer_id = params[:customer].is_a?(Stripe::Customer) ? params[:customer][:id] : params[:customer].to_s
        customer = assert_existence :customer, customer_id, customers[stripe_account][customer_id]

        phase_params = normalize_schedule_list(params[:phases])
        require_param(:phases) if phase_params.empty?

        now = Time.now.utc.to_i
        start_date = params[:start_date].nil? || params[:start_date] == 'now' ? now : params[:start_date].to_i

        schedule = Data.mock_subscription_schedule(
          id: new_id('sub_sched'),
          customer: customer[:id],
          created: now,
          end_behavior: params[:end_behavior] || 'release',
          metadata: params[:metadata] || {},
          default_settings: schedule_default_settings(params[:default_settings]),
          phases: build_schedule_phases(phase_params, start_date)
        )

        if start_date <= now
          start_schedule_subscription(schedule, customer)
        end

        refresh_schedule_state(schedule)
        subscription_schedules[schedule[:id]] = schedule
      end

      def get_subscription_schedule(route, method_url, params, headers)
        route =~ method_url
        schedule = assert_existence :subscription_schedule, $1, subscription_schedules[$1]
        refresh_schedule_state(schedule)
      end

      def list_subscription_schedules(route, method_url, params, headers)
        schedules = subscription_schedules.values.map { |schedule| refresh_schedule_state(schedule) }

        if params[:customer]
          schedules = schedules.select { |schedule| schedule[:customer] == params[:customer] }
        end
        if params.key?(:scheduled)
          scheduled = [true, 'true'].include?(params[:scheduled])
          schedules = schedules.select { |schedule| (schedule[:status] == 'not_started') == scheduled }
        end
        %i(canceled_at completed_at released_at).each do |field|
          next unless params[field]

          schedules = filter_by_timestamp(schedules.select { |schedule| schedule[field] }, field: field, value: params[field])
        end

        Data.mock_list_object(schedules.sort_by { |schedule| -schedule[:created].to_i }, params)
      end

      def update_subscription_schedule(route, method_url, params, headers)
        stripe_account = headers && headers[:stripe_account] || Stripe.api_key
        route =~ method_url
        schedule = assert_existence :subscription_schedule, $1, subscription_schedules[$1]
        assert_schedule_mutable(schedule, 'update')
        reject_unknown_schedule_params(params, SCHEDULE_UPDATE_PARAMS)
        validate_schedule_end_behavior(params[:end_behavior])

        schedule[:end_behavior] = params[:end_behavior] if params[:end_behavior]
        schedule[:metadata] = (schedule[:metadata] || {}).merge(params[:metadata]) if params[:metadata]
        schedule[:default_settings] = schedule_default_settings(params[:default_settings], schedule[:default_settings]) if params[:default_settings]

        if params.key?(:phases)
          phase_params = normalize_schedule_list(params[:phases])
          require_param(:phases) if phase_params.empty?

          first_start = phase_params.first[:start_date]
          start_date = if first_start.nil?
                         schedule[:phases].first && schedule[:phases].first[:start_date] || Time.now.utc.to_i
                       elsif first_start == 'now'
                         Time.now.utc.to_i
                       else
                         first_start.to_i
                       end
          schedule[:phases] = build_schedule_phases(phase_params, start_date)

          customer = assert_existence :customer, schedule[:customer], customers[stripe_account][schedule[:customer]]
          if schedule[:subscription]
            sync_schedule_subscription(schedule, customer)
          elsif start_date <= Time.now.utc.to_i
            start_schedule_subscription(schedule, customer)
          end
        end

        refresh_schedule_state(schedule)
      end

      def cancel_subscription_schedule(route, method_url, params, headers)
        stripe_account = headers && headers[:stripe_account] || Stripe.api_key
        route =~ method_url
        schedule = assert_existence :subscription_schedule, $1, subscription_schedules[$1]
        assert_schedule_mutable(schedule, 'cancel')

        now = Time.now.utc.to_i
        if (subscription = schedule[:subscription] && subscriptions[schedule[:subscription]])
          customer = customers[stripe_account][subscription[:customer]]
          subscription.merge!(status: 'canceled', canceled_at: now, ended_at: now, cancel_at_period_end: false)
          delete_subscription_from_customer(customer, subscription) if customer
        end

        schedule.merge!(status: 'canceled', canceled_at: now, current_phase: nil)
      end

      def release_subscription_schedule(route, method_url, params, headers)
        route =~ method_url
        schedule = assert_existence :subscription_schedule, $1, subscription_schedules[$1]
        assert_schedule_mutable(schedule, 'release')

        subscription_id = schedule[:subscription]
        subscriptions[subscription_id][:schedule] = nil if subscription_id && subscriptions[subscription_id]

        schedule.merge!(
          status: 'released',
          released_at: Time.now.utc.to_i,
          released_subscription: subscription_id,
          subscription: nil,
          current_phase: nil
        )
      end

      private

      def schedule_from_subscription(params, stripe_account)
        conflicting = params.keys & %i(customer phases start_date end_behavior default_settings)
        if conflicting.any?
          raise Stripe::InvalidRequestError.new(
            "You cannot set `#{conflicting.first}` if `from_subscription` is set.", conflicting.first.to_s, http_status: 400
          )
        end

        subscription_id = params[:from_subscription].to_s
        subscription = assert_existence :subscription, subscription_id, subscriptions[subscription_id]
        if subscription[:status] == 'canceled'
          raise Stripe::InvalidRequestError.new(
            "You cannot migrate a canceled subscription to a subscription schedule.", 'from_subscription', http_status: 400
          )
        end
        if subscription[:schedule]
          raise Stripe::InvalidRequestError.new(
            "You cannot migrate a subscription that is already attached to a schedule: `#{subscription[:schedule]}`.",
            'from_subscription', http_status: 400
          )
        end

        items = subscription[:items][:data].map do |item|
          price = item[:price] || item[:plan]
          schedule_phase_item(price[:id], item[:quantity] || 1, item[:metadata] || {})
        end

        schedule = Data.mock_subscription_schedule(
          id: new_id('sub_sched'),
          customer: subscription[:customer],
          created: Time.now.utc.to_i,
          end_behavior: 'release',
          metadata: params[:metadata] || {},
          subscription: subscription[:id],
          phases: [schedule_phase(
            items: items,
            start_date: subscription[:current_period_start],
            end_date: subscription[:current_period_end],
            trial_end: subscription[:trial_end],
            metadata: {},
            collection_method: subscription[:collection_method],
            default_payment_method: subscription[:default_payment_method]
          )]
        )
        subscription[:schedule] = schedule[:id]

        refresh_schedule_state(schedule)
        subscription_schedules[schedule[:id]] = schedule
      end

      # Lays the phases end to end. Each phase starts when the previous one ends and lasts until its
      # `end_date`, or for `iterations` billing intervals of its first item's price (one interval by default).
      def build_schedule_phases(phase_params, start_date)
        phase_start = start_date
        phase_params.each_with_index.map do |phase, index|
          reject_unknown_phase_params(phase, index)

          item_params = normalize_schedule_list(phase[:items])
          raise Stripe::InvalidRequestError.new(missing_param_message("phases[#{index}][items]"), "phases[#{index}][items]", http_status: 400) if item_params.empty?

          if phase[:end_date] && phase[:iterations]
            raise Stripe::InvalidRequestError.new(
              "You may only specify one of these parameters: phases[#{index}][end_date], phases[#{index}][iterations].",
              "phases[#{index}][end_date]", http_status: 400
            )
          end

          items = item_params.each_with_index.map do |item, item_index|
            price_id = (item[:price] || item[:plan]).to_s
            raise Stripe::InvalidRequestError.new(missing_param_message("phases[#{index}][items][#{item_index}][price]"), "phases[#{index}][items][#{item_index}][price]", http_status: 400) if price_id.empty?
            assert_existence(:price, price_id, prices[price_id] || plans[price_id])
            schedule_phase_item(price_id, (item[:quantity] || 1).to_i, item[:metadata] || {})
          end

          if phase[:coupon] && !coupons[phase[:coupon]]
            raise Stripe::InvalidRequestError.new("No such coupon: '#{phase[:coupon]}'", "phases[#{index}][coupon]", http_status: 400)
          end

          phase_end = if phase[:end_date]
                        phase[:end_date] == 'now' ? Time.now.utc.to_i : phase[:end_date].to_i
                      else
                        first_price = prices[items.first[:price]] || plans[items.first[:price]]
                        get_ending_time(phase_start, first_price, (phase[:iterations] || 1).to_i)
                      end

          if phase_end <= phase_start
            raise Stripe::InvalidRequestError.new(
              "The end_date of phase #{index} must be after its start_date.", "phases[#{index}][end_date]", http_status: 400
            )
          end

          trial_end = phase[:trial] ? phase_end : phase[:trial_end]
          trial_end = trial_end.to_i if trial_end && trial_end != 'now'

          built = schedule_phase(
            items: items,
            start_date: phase_start,
            end_date: phase_end,
            trial_end: trial_end == 'now' ? nil : trial_end,
            coupon: phase[:coupon],
            metadata: phase[:metadata] || {},
            collection_method: phase[:collection_method],
            default_payment_method: phase[:default_payment_method],
            proration_behavior: phase[:proration_behavior] || 'create_prorations',
            description: phase[:description]
          )
          phase_start = phase_end
          built
        end
      end

      def schedule_phase(attrs)
        {
          add_invoice_items: [],
          application_fee_percent: nil,
          billing_cycle_anchor: nil,
          billing_thresholds: nil,
          collection_method: nil,
          coupon: nil,
          currency: nil,
          default_payment_method: nil,
          default_tax_rates: [],
          description: nil,
          discounts: [],
          invoice_settings: nil,
          metadata: {},
          on_behalf_of: nil,
          proration_behavior: 'create_prorations',
          transfer_data: nil,
          trial_end: nil
        }.merge(attrs.compact).tap do |phase|
          first_price = prices[phase[:items].first[:price]] || plans[phase[:items].first[:price]]
          phase[:currency] ||= first_price && first_price[:currency]
        end
      end

      def schedule_phase_item(price_id, quantity, metadata)
        {
          billing_thresholds: nil,
          discounts: [],
          metadata: metadata,
          plan: price_id,
          price: price_id,
          quantity: quantity,
          tax_rates: []
        }
      end

      def schedule_default_settings(params, existing = nil)
        base = existing || Data.mock_subscription_schedule[:default_settings]
        return base unless params

        base.merge(params.select { |key, _| base.key?(key) })
      end

      def current_schedule_phase(schedule, now = Time.now.utc.to_i)
        schedule[:phases].find { |phase| phase[:start_date] <= now && now < phase[:end_date] }
      end

      # Creates the subscription a schedule manages once its first phase has started.
      def start_schedule_subscription(schedule, customer)
        phase = current_schedule_phase(schedule) || schedule[:phases].first
        params = schedule_subscription_params(phase)
        plans_for_phase = phase[:items].map { |item| prices[item[:price]] || plans[item[:price]] }

        subscription = Data.mock_subscription(id: new_id('su'))
        subscription = resolve_subscription_changes(subscription, plans_for_phase, customer, params)
        subscription[:status] = 'trialing' if phase[:trial_end] && phase[:trial_end] > Time.now.utc.to_i
        verify_card_present(customer, plans_for_phase.first, subscription, params)
        add_coupon_to_object(subscription, coupons[phase[:coupon]]) if phase[:coupon]

        subscription[:schedule] = schedule[:id]
        subscription[:start_date] = phase[:start_date]
        subscriptions[subscription[:id]] = subscription
        add_subscription_to_customer(customer, subscription)
        schedule[:subscription] = subscription[:id]
        subscription
      end

      # Keeps a running subscription in step with the schedule's current phase after an update.
      def sync_schedule_subscription(schedule, customer)
        subscription = subscriptions[schedule[:subscription]]
        phase = current_schedule_phase(schedule)
        return unless subscription && phase

        params = schedule_subscription_params(phase)
        params[:current_period_start] = subscription[:current_period_start]
        plans_for_phase = phase[:items].map { |item| prices[item[:price]] || plans[item[:price]] }
        resolve_subscription_changes(subscription, plans_for_phase, customer, params)
        add_coupon_to_object(subscription, coupons[phase[:coupon]]) if phase[:coupon]

        customer[:subscriptions][:data].reject! { |sub| sub[:id] == subscription[:id] }
        customer[:subscriptions][:data] << subscription
      end

      def schedule_subscription_params(phase)
        params = {
          items: phase[:items].map { |item| { price: item[:price], quantity: item[:quantity], metadata: item[:metadata] } },
          current_period_start: phase[:start_date],
          metadata: phase[:metadata]
        }
        params[:trial_end] = phase[:trial_end] if phase[:trial_end] && phase[:trial_end] > Time.now.utc.to_i
        params[:collection_method] = phase[:collection_method] if phase[:collection_method]
        params[:default_payment_method] = phase[:default_payment_method] if phase[:default_payment_method]
        params
      end

      # Derives status and current_phase from the phase timeline, the way Stripe reports them.
      def refresh_schedule_state(schedule)
        return schedule unless SCHEDULE_MUTABLE_STATUSES.include?(schedule[:status])

        now = Time.now.utc.to_i
        phases = schedule[:phases]
        if phases.empty? || now < phases.first[:start_date]
          schedule[:status] = 'not_started'
          schedule[:current_phase] = nil
        elsif now >= phases.last[:end_date]
          finish_schedule(schedule, phases.last[:end_date])
        else
          phase = current_schedule_phase(schedule, now)
          schedule[:status] = 'active'
          schedule[:current_phase] = { start_date: phase[:start_date], end_date: phase[:end_date] }
        end
        schedule
      end

      def finish_schedule(schedule, ended_at)
        subscription = schedule[:subscription] && subscriptions[schedule[:subscription]]
        if schedule[:end_behavior] == 'cancel'
          if subscription && subscription[:status] != 'canceled'
            subscription.merge!(status: 'canceled', canceled_at: ended_at, ended_at: ended_at)
            customer = customers.values.map { |by_id| by_id[subscription[:customer]] }.compact.first
            delete_subscription_from_customer(customer, subscription) if customer
          end
          schedule.merge!(status: 'completed', completed_at: ended_at, current_phase: nil)
        else
          subscription[:schedule] = nil if subscription
          schedule.merge!(
            status: 'released',
            released_at: ended_at,
            released_subscription: schedule[:subscription],
            subscription: nil,
            current_phase: nil
          )
        end
      end

      def assert_schedule_mutable(schedule, action)
        return if SCHEDULE_MUTABLE_STATUSES.include?(refresh_schedule_state(schedule)[:status])

        raise Stripe::InvalidRequestError.new(
          "You cannot #{action} a subscription schedule that is currently in the `#{schedule[:status]}` status. " \
          "It must be in one of the following statuses: `not_started`, `active`.",
          nil, http_status: 400
        )
      end

      def validate_schedule_end_behavior(end_behavior)
        return if end_behavior.nil? || SCHEDULE_END_BEHAVIORS.include?(end_behavior.to_s)

        raise Stripe::InvalidRequestError.new(
          "Invalid end_behavior: must be one of #{SCHEDULE_END_BEHAVIORS.join(' or ')}", 'end_behavior', http_status: 400
        )
      end

      def reject_unknown_schedule_params(params, allowed)
        unknown = params.keys - allowed
        return if unknown.empty?

        raise Stripe::InvalidRequestError.new("Received unknown parameter: #{unknown.first}", unknown.first.to_s, http_status: 400)
      end

      def reject_unknown_phase_params(phase, index)
        unknown = phase.keys - SCHEDULE_PHASE_PARAMS
        return if unknown.empty?

        raise Stripe::InvalidRequestError.new(
          "Received unknown parameter: phases[#{index}][#{unknown.first}]", "phases[#{index}][#{unknown.first}]", http_status: 400
        )
      end

      def normalize_schedule_list(list)
        return [] if list.nil? || list == ''

        list = list.values if list.respond_to?(:values)
        list.map { |entry| entry.respond_to?(:to_hash) ? entry.to_hash : entry }
      end
    end
  end
end
