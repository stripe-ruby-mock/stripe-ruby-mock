require 'spec_helper'

shared_examples 'Subscription Schedule API' do
  let(:product) { stripe_helper.create_product }
  let(:monthly_price) do
    stripe_helper.create_price(product: product.id, unit_amount: 2000, currency: 'usd', recurring: { interval: 'month' })
  end
  let(:annual_price) do
    stripe_helper.create_price(product: product.id, unit_amount: 20000, currency: 'usd', recurring: { interval: 'year' })
  end
  let(:customer) { Stripe::Customer.create(source: stripe_helper.generate_card_token) }

  def two_phase_schedule(overrides = {})
    Stripe::SubscriptionSchedule.create({
      customer: customer.id,
      start_date: 'now',
      end_behavior: 'release',
      phases: [
        { items: [{ price: monthly_price.id, quantity: 2 }], iterations: 3 },
        { items: [{ price: annual_price.id }], iterations: 1 }
      ]
    }.merge(overrides))
  end

  context 'creating a schedule' do
    it 'starts now, lays phases end to end and creates the managed subscription' do
      schedule = two_phase_schedule(metadata: { plan: 'upgrade' })

      expect(schedule.id).to match(/^(test_)?sub_sched_/)
      expect(schedule.object).to eq('subscription_schedule')
      expect(schedule.status).to eq('active')
      expect(schedule.customer).to eq(customer.id)
      expect(schedule.end_behavior).to eq('release')
      expect(schedule.metadata.to_h).to eq(plan: 'upgrade')

      first, second = schedule.phases
      expect(first.start_date).to be_within(5).of(Time.now.to_i)
      expect(first.end_date).to eq((Time.at(first.start_date).to_datetime >> 3).to_time.to_i)
      expect(second.start_date).to eq(first.end_date)
      expect(second.end_date).to eq((Time.at(second.start_date).to_datetime >> 12).to_time.to_i)
      expect(first.items.first.price).to eq(monthly_price.id)
      expect(first.items.first.quantity).to eq(2)
      expect(schedule.current_phase.to_h).to eq(start_date: first.start_date, end_date: first.end_date)

      subscription = Stripe::Subscription.retrieve(schedule.subscription)
      expect(subscription.schedule).to eq(schedule.id)
      expect(subscription.status).to eq('active')
      expect(subscription.items.data.map { |item| [item.price.id, item.quantity] }).to eq([[monthly_price.id, 2]])
      expect(Stripe::Customer.retrieve(customer.id).subscriptions.data.map(&:id)).to include(subscription.id)
    end

    it 'does not create a subscription for a schedule that starts in the future' do
      start = Time.now.to_i + 7 * 86400
      schedule = two_phase_schedule(start_date: start)

      expect(schedule.status).to eq('not_started')
      expect(schedule.subscription).to be_nil
      expect(schedule.current_phase).to be_nil
      expect(schedule.phases.first.start_date).to eq(start)
      expect(Stripe::Customer.retrieve(customer.id).subscriptions.data).to be_empty
    end

    it 'honors explicit phase end dates and trials' do
      trial_end = Time.now.to_i + 14 * 86400
      end_date = Time.now.to_i + 30 * 86400
      schedule = Stripe::SubscriptionSchedule.create(
        customer: customer.id,
        start_date: 'now',
        phases: [{ items: [{ price: monthly_price.id }], end_date: end_date, trial_end: trial_end }]
      )

      expect(schedule.phases.first.end_date).to eq(end_date)
      expect(schedule.phases.first.trial_end).to eq(trial_end)
      subscription = Stripe::Subscription.retrieve(schedule.subscription)
      expect(subscription.status).to eq('trialing')
      expect(subscription.trial_end).to eq(trial_end)
    end

    it 'applies a phase coupon to the subscription' do
      coupon = stripe_helper.create_coupon(id: 'SCHEDULE10', amount_off: 1000, currency: 'usd', duration: 'once')
      schedule = Stripe::SubscriptionSchedule.create(
        customer: customer.id,
        start_date: 'now',
        phases: [{ items: [{ price: monthly_price.id }], coupon: coupon.id }]
      )

      expect(schedule.phases.first.coupon).to eq('SCHEDULE10')
      expect(Stripe::Subscription.retrieve(schedule.subscription).discount.coupon.id).to eq('SCHEDULE10')
    end

    it 'migrates an existing subscription with from_subscription' do
      subscription = Stripe::Subscription.create(customer: customer.id, items: [{ price: monthly_price.id, quantity: 3 }])

      schedule = Stripe::SubscriptionSchedule.create(from_subscription: subscription.id)

      expect(schedule.status).to eq('active')
      expect(schedule.subscription).to eq(subscription.id)
      expect(schedule.customer).to eq(customer.id)
      expect(schedule.end_behavior).to eq('release')
      expect(schedule.phases.length).to eq(1)
      expect(schedule.phases.first.start_date).to eq(subscription.current_period_start)
      expect(schedule.phases.first.end_date).to eq(subscription.current_period_end)
      expect(schedule.phases.first.items.map { |item| [item.price, item.quantity] }).to eq([[monthly_price.id, 3]])
      expect(Stripe::Subscription.retrieve(subscription.id).schedule).to eq(schedule.id)
    end

    it 'rejects migrating a subscription that already has a schedule' do
      subscription = Stripe::Subscription.create(customer: customer.id, items: [{ price: monthly_price.id }])
      schedule = Stripe::SubscriptionSchedule.create(from_subscription: subscription.id)

      expect { Stripe::SubscriptionSchedule.create(from_subscription: subscription.id) }.to raise_error { |e|
        expect(e).to be_a(Stripe::InvalidRequestError)
        expect(e.message).to include(schedule.id)
      }
    end

    it 'rejects phases together with from_subscription' do
      subscription = Stripe::Subscription.create(customer: customer.id, items: [{ price: monthly_price.id }])

      expect {
        Stripe::SubscriptionSchedule.create(from_subscription: subscription.id, phases: [{ items: [{ price: monthly_price.id }] }])
      }.to raise_error(Stripe::InvalidRequestError, /You cannot set `phases` if `from_subscription` is set/)
    end

    it 'validates the request' do
      expect { Stripe::SubscriptionSchedule.create(phases: [{ items: [{ price: monthly_price.id }] }]) }
        .to raise_error(Stripe::InvalidRequestError, /Missing required param: customer/)
      expect { Stripe::SubscriptionSchedule.create(customer: customer.id) }
        .to raise_error(Stripe::InvalidRequestError, /Missing required param: phases/)
      expect { Stripe::SubscriptionSchedule.create(customer: customer.id, phases: [{ iterations: 1 }]) }
        .to raise_error(Stripe::InvalidRequestError, /phases\[0\]\[items\]/)
      expect { Stripe::SubscriptionSchedule.create(customer: customer.id, phases: [{ items: [{ price: 'price_missing' }] }]) }
        .to raise_error(Stripe::InvalidRequestError, /No such price: price_missing/)
      expect {
        Stripe::SubscriptionSchedule.create(customer: customer.id, phases: [{ items: [{ price: monthly_price.id }], iterations: 2, end_date: Time.now.to_i + 86400 }])
      }.to raise_error(Stripe::InvalidRequestError, /only specify one of these parameters/)
      expect {
        Stripe::SubscriptionSchedule.create(customer: customer.id, end_behavior: 'renew', phases: [{ items: [{ price: monthly_price.id }] }])
      }.to raise_error(Stripe::InvalidRequestError, /end_behavior/)
      expect {
        Stripe::SubscriptionSchedule.create(customer: customer.id, phases: [{ items: [{ price: monthly_price.id }], coupon: 'NOPE' }])
      }.to raise_error(Stripe::InvalidRequestError, /No such coupon/)
    end
  end

  context 'retrieving and listing' do
    it 'retrieves a schedule' do
      schedule = two_phase_schedule
      expect(Stripe::SubscriptionSchedule.retrieve(schedule.id).phases.length).to eq(2)
    end

    it 'raises for an unknown schedule' do
      expect { Stripe::SubscriptionSchedule.retrieve('sub_sched_missing') }.to raise_error { |e|
        expect(e).to be_a(Stripe::InvalidRequestError)
        expect(e.http_status).to eq(404)
        expect(e.message).to eq('No such subscription_schedule: sub_sched_missing')
      }
    end

    it 'filters by customer and by scheduled' do
      other_customer = Stripe::Customer.create(source: stripe_helper.generate_card_token)
      active = two_phase_schedule
      upcoming = two_phase_schedule(start_date: Time.now.to_i + 86400)
      other = two_phase_schedule(customer: other_customer.id)

      expect(Stripe::SubscriptionSchedule.list(customer: customer.id).data.map(&:id)).to contain_exactly(active.id, upcoming.id)
      expect(Stripe::SubscriptionSchedule.list(scheduled: true).data.map(&:id)).to eq([upcoming.id])
      expect(Stripe::SubscriptionSchedule.list.data.map(&:id)).to contain_exactly(active.id, upcoming.id, other.id)
    end
  end

  context 'updating' do
    it 'replaces phases and moves the running subscription to the new current phase' do
      schedule = two_phase_schedule
      start = schedule.phases.first.start_date

      updated = Stripe::SubscriptionSchedule.update(schedule.id,
        metadata: { reason: 'downgrade' },
        end_behavior: 'cancel',
        phases: [
          { start_date: start, items: [{ price: annual_price.id, quantity: 5 }], iterations: 1 }
        ])

      expect(updated.end_behavior).to eq('cancel')
      expect(updated.metadata.reason).to eq('downgrade')
      expect(updated.phases.length).to eq(1)
      expect(updated.phases.first.start_date).to eq(start)
      expect(updated.phases.first.end_date).to eq((Time.at(start).to_datetime >> 12).to_time.to_i)

      subscription = Stripe::Subscription.retrieve(schedule.subscription)
      expect(subscription.items.data.map { |item| [item.price.id, item.quantity] }).to eq([[annual_price.id, 5]])
    end

    it 'starts a not-yet-started schedule when its phases are moved to now' do
      schedule = two_phase_schedule(start_date: Time.now.to_i + 86400)

      updated = Stripe::SubscriptionSchedule.update(schedule.id,
        phases: [{ start_date: 'now', items: [{ price: monthly_price.id }] }])

      expect(updated.status).to eq('active')
      expect(Stripe::Subscription.retrieve(updated.subscription).schedule).to eq(schedule.id)
    end
  end

  context 'releasing and canceling' do
    it 'releases a schedule and leaves the subscription running' do
      schedule = two_phase_schedule

      released = Stripe::SubscriptionSchedule.release(schedule.id)

      expect(released.status).to eq('released')
      expect(released.released_at).to be_within(5).of(Time.now.to_i)
      expect(released.released_subscription).to eq(schedule.subscription)
      expect(released.subscription).to be_nil
      subscription = Stripe::Subscription.retrieve(schedule.subscription)
      expect(subscription.status).to eq('active')
      expect(subscription.schedule).to be_nil
    end

    it 'cancels a schedule together with its subscription' do
      schedule = two_phase_schedule

      canceled = Stripe::SubscriptionSchedule.cancel(schedule.id)

      expect(canceled.status).to eq('canceled')
      expect(canceled.canceled_at).to be_within(5).of(Time.now.to_i)
      expect(Stripe::Subscription.retrieve(schedule.subscription).status).to eq('canceled')
      expect(Stripe::Customer.retrieve(customer.id).subscriptions.data).to be_empty
    end

    it 'cancels the schedule when its subscription is canceled' do
      schedule = two_phase_schedule

      subscription = Stripe::Subscription.retrieve(schedule.subscription)
      subscription.respond_to?(:cancel) ? subscription.cancel : subscription.delete

      expect(Stripe::SubscriptionSchedule.retrieve(schedule.id).status).to eq('canceled')
    end

    it 'does not allow changing a schedule once it is released or canceled' do
      released = Stripe::SubscriptionSchedule.release(two_phase_schedule.id)
      canceled = Stripe::SubscriptionSchedule.cancel(two_phase_schedule.id)

      expect { Stripe::SubscriptionSchedule.cancel(released.id) }
        .to raise_error(Stripe::InvalidRequestError, /currently in the `released` status/)
      expect { Stripe::SubscriptionSchedule.release(canceled.id) }
        .to raise_error(Stripe::InvalidRequestError, /currently in the `canceled` status/)
      expect { Stripe::SubscriptionSchedule.update(canceled.id, metadata: { a: 'b' }) }
        .to raise_error(Stripe::InvalidRequestError, /cannot update a subscription schedule/)
    end
  end

  context 'when the last phase has already ended' do
    it 'completes the schedule and cancels the subscription when end_behavior is cancel' do
      start = Time.now.to_i - 40 * 86400
      schedule = two_phase_schedule(
        start_date: start,
        end_behavior: 'cancel',
        phases: [{ items: [{ price: monthly_price.id }], end_date: start + 30 * 86400 }]
      )

      expect(schedule.status).to eq('completed')
      expect(schedule.completed_at).to eq(start + 30 * 86400)
      expect(Stripe::Subscription.retrieve(schedule.subscription).status).to eq('canceled')
    end

    it 'releases the subscription when end_behavior is release' do
      start = Time.now.to_i - 40 * 86400
      schedule = two_phase_schedule(
        start_date: start,
        phases: [{ items: [{ price: monthly_price.id }], end_date: start + 30 * 86400 }]
      )

      expect(schedule.status).to eq('released')
      expect(schedule.released_subscription).not_to be_nil
      expect(Stripe::Subscription.retrieve(schedule.released_subscription).status).to eq('active')
    end
  end
end
