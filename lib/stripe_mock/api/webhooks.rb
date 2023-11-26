module StripeMock

  def self.mock_webhook_payload(type, params = {})

    fixture_file = File.join(@webhook_fixture_path, "#{type}.json")

    unless File.exist?(fixture_file)
      unless Webhooks.event_list.include?(type)
        raise UnsupportedRequestError.new "Unsupported webhook event `#{type}` (Searched in #{@webhook_fixture_path})"
      end
      fixture_file = File.join(@webhook_fixture_fallback_path, "#{type}.json")
    end

    json = MultiJson.load  File.read(fixture_file)

    json = Stripe::Util.symbolize_names(json)
    params = Stripe::Util.symbolize_names(params)
    json[:account] = params.delete(:account) if params.key?(:account)
    json[:data][:object] = Util.rmerge(json[:data][:object], params)
    json.delete(:id)
    json[:created] = params[:created] || Time.now.to_i

    if @state == 'local'
      event_data = instance.generate_webhook_event(json)
    elsif @state == 'remote'
      event_data = client.generate_webhook_event(json)
    else
      raise UnstartedStateError
    end
    event_data
  end

  def self.mock_webhook_event(type, params={})
    Stripe::Event.construct_from(mock_webhook_payload(type, params))
  end

  module Webhooks
    def self.event_list
      @__list = [
        'account.application.deauthorized',
        'account.external_account.created',
        'account.external_account.deleted',
        'account.external_account.updated',
        'account.updated',
        'balance.available',
        'charge.captured',
        'charge.dispute.closed',
        'charge.dispute.created',
        'charge.dispute.funds_reinstated',
        'charge.dispute.funds_withdrawn',
        'charge.dispute.updated',
        'charge.failed',
        'charge.refund.updated',
        'charge.refunded',
        'charge.succeeded',
        'charge.updated',
        'checkout.session.completed',
        'checkout.session.completed.payment_mode',
        'checkout.session.completed.setup_mode',
        'coupon.created',
        'coupon.deleted',
        'customer.created',
        'customer.deleted',
        'customer.discount.created',
        'customer.discount.deleted',
        'customer.discount.updated',
        'customer.source.created',
        'customer.source.deleted',
        'customer.source.updated',
        'customer.subscription.created',
        'customer.subscription.deleted',
        'customer.subscription.trial_will_end',
        'customer.subscription.updated',
        'customer.updated',
        'invoice.created',
        'invoice.finalized',
        'invoice.paid',
        'invoice.payment_action_required',
        'invoice.payment_failed',
        'invoice.payment_succeeded',
        'invoice.upcoming',
        'invoice.updated',
        'invoiceitem.created',
        'invoiceitem.deleted',
        'invoiceitem.updated',
        'mandate.updated',
        'payment_intent.amount_capturable_updated',
        'payment_intent.canceled',
        'payment_intent.created',
        'payment_intent.payment_failed',
        'payment_intent.processing',
        'payment_intent.requires_action',
        'payment_intent.succeeded',
        'payment_link.created',
        'payment_link.updated',
        'payment_method.attached',
        'payment_method.detached',
        'payout.created',
        'payout.paid',
        'payout.updated',
        'plan.created',
        'plan.deleted',
        'plan.updated',
        'price.created',
        'price.deleted',
        'price.updated',
        'product.created',
        'product.deleted',
        'product.updated',
        'quote.accepted',
        'quote.canceled',
        'quote.created',
        'quote.finalized',
        'setup_intent.canceled',
        'setup_intent.created',
        'setup_intent.setup_failed',
        'setup_intent.succeeded',
        'subscription_schedule.canceled',
        'subscription_schedule.created',
        'subscription_schedule.released',
        'subscription_schedule.updated',
        'tax_rate.created',
        'tax_rate.updated',
        'transfer.created',
        'transfer.failed',
        'transfer.paid',
        'transfer.updated'
      ]
    end
  end

end
