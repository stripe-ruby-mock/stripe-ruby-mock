module StripeMock

  def self.mock_webhook_event(type, params={})

    fixture_file = File.join(@webhook_fixture_path, "#{type}.json")

    if File.exists?(fixture_file) == false
      unless Webhooks.event_list.include?(type)
        raise UnsupportedRequestError.new "Unsupported webhook event `#{type}` (Searched in #{@webhook_fixture_path})"
      end
      fixture_file = File.join(@webhook_fixture_fallback_path, "#{type}.json")
    end

    json = MultiJson.load  File.read(fixture_file)

    json = Stripe::Util.symbolize_names(json)
    params = Stripe::Util.symbolize_names(params)
    json[:data][:object] = Util.rmerge(json[:data][:object], params)
    json.delete(:id)

    if @state == 'local'
      event_data = instance.generate_event(json)
    elsif @state == 'remote'
      event_data = client.generate_event(json)
    else
      raise UnstartedStateError
    end

    Stripe::Event.construct_from(event_data)
  end

  module Webhooks
    def self.event_list
      @__list = [
        'account.updated',
        'account.application.deauthorized',
        'balance.available',
        'charge.succeeded',
        'charge.failed',
        'charge.refunded',
        'charge.dispute.created',
        'charge.dispute.updated',
        'charge.dispute.closed',
        'customer.created',
        'customer.updated',
        'customer.deleted',
        'customer.subscription.created',
        'customer.subscription.updated',
        'customer.subscription.deleted',
        'customer.subscription.trial_will_end',
        'customer.discount.created',
        'customer.discount.updated',
        'customer.discount.deleted',
        'invoice.created',
        'invoice.updated',
        'invoice.payment_succeeded',
        'invoice.payment_failed',
        'invoiceitem.created',
        'invoiceitem.updated',
        'invoiceitem.deleted',
        'plan.created',
        'plan.updated',
        'plan.deleted',
        'coupon.created',
        'coupon.deleted',
        'transfer.created',
        'transfer.paid',
        'transfer.updated',
        'transfer.failed'
      ]
    end
  end

end
