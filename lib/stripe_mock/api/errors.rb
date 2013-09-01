module StripeMock

  def self.prepare_error(stripe_error, *handler_names)
    handler_names.push(:all) if handler_names.count == 0

    if @state == 'local'
      instance.error_queue.queue(stripe_error, handler_names)
    elsif @state == 'remote'
      client.error_queue.queue(stripe_error, handler_names)
    else
      raise UnstartedStateError
    end
  end

  def self.prepare_card_error(code, *handler_names)
    if handler_names.count == 0
      handler_names.push(:new_charge)
      handler_names.push(:store_card)
    end

    args = CardErrors.argument_map[code]
    raise StripeMockError.new("Unrecognized stripe card error code: #{code}") if args.nil?
    self.prepare_error  Stripe::CardError.new(*args), *handler_names
  end

  module CardErrors

    def self.argument_map
      @__map ||= {
        incorrect_number: ["Your card number is incorrect.", 'number', 'incorrect_number', 402],
        invalid_number: ["Your card number is not a valid credit card number.", 'number', 'invalid_number', 402],
        invalid_expiry_month: ["Your card's expiration month is invalid.", 'exp_month', 'invalid_expiry_month', 402],
        invalid_expiry_year: ["Your card's expiration year is invalid.", 'exp_year', 'invalid_expiry_year', 402],
        invalid_cvc: ["Your card's security code is invalid", 'cvc', 'invalid_cvc', 402],
        expired_card: ["Your card has expired.", 'exp_month', 'expired_card', 402],
        incorrect_cvc: ["Your card's security code is incorrect.", 'cvc', 'incorrect_cvc', 402],
        card_declined: ["Your card was declined.", nil, 'card_declined', 402],
        missing: ["There is no card on a customer that is being charged.", nil, 'missing', 402],
        processing_error: ["An error occurred while processing your card.", nil, 'processing_error', 402],
      }
    end
  end

end
