module StripeMock

  def self.mock_webhook_event(type, params={})
    unless Webhooks.event_list.include?(type)
      raise UnsupportedRequestError.new "Unsupported webhook event `#{type}`"
    end
    json = MultiJson.load  File.read  File.join(@webhook_fixture_path, "#{type}.json")

    json = Stripe::Util.symbolize_names(json)
    params = Stripe::Util.symbolize_names(params)
    Stripe::Event.construct_from Util.rmerge(json, params)
  end

  module Webhooks
    def self.event_list
      @__list = [
        'account.updated',
        'account.application.deauthorized',
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
