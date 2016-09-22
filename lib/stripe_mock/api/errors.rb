module StripeMock

  def self.prepare_error(stripe_error, *handler_names)
    handler_names.push(:all) if handler_names.count == 0

    if @state == 'local'
      instance
    elsif @state == 'remote'
      client
    else
      raise UnstartedStateError
    end.error_queue.queue stripe_error, handler_names
  end

  def self.prepare_card_error(code, *handler_names)
    handler_names.push(:new_charge) if handler_names.count == 0

    args = CardErrors.argument_map[code]
    raise StripeMockError.new("Unrecognized stripe card error code: #{code}") if args.nil?
    self.prepare_error Stripe::CardError.new(*args), *handler_names
  end

  module CardErrors

    def self.argument_map
      @__map ||= {
        incorrect_number: add_json_body(["The card number is incorrect", 'number', 'incorrect_number', 402]),
        invalid_number: add_json_body(["The card number is not a valid credit card number", 'number', 'invalid_number', 402]),
        invalid_expiry_month: add_json_body(["The card's expiration month is invalid", 'exp_month', 'invalid_expiry_month', 402]),
        invalid_expiry_year: add_json_body(["The card's expiration year is invalid", 'exp_year', 'invalid_expiry_year', 402]),
        invalid_cvc: add_json_body(["The card's security code is invalid", 'cvc', 'invalid_cvc', 402]),
        expired_card: add_json_body(["The card has expired", 'exp_month', 'expired_card', 402]),
        incorrect_cvc: add_json_body(["The card's security code is incorrect", 'cvc', 'incorrect_cvc', 402]),
        card_declined: add_json_body(["The card was declined", nil, 'card_declined', 402]),
        missing: add_json_body(["There is no card on a customer that is being charged.", nil, 'missing', 402]),
        processing_error: add_json_body(["An error occurred while processing the card", nil, 'processing_error', 402]),
        card_error: add_json_body(['The card number is not a valid credit card number.', 'number', 'invalid_number', 402]), 
        incorrect_zip: add_json_body(['The zip code you supplied failed validation.', 'address_zip', 'incorrect_zip', 402])
      }
    end

    def self.add_json_body(error_values)
      error_keys = [:message, :param, :code]

      json_hash = Hash[error_keys.zip error_values]
      json_hash[:type] = 'card_error'

      error_values.push(error: json_hash) # http_body
      error_values.push(error: json_hash) # json_body

      error_values
    end
  end
end
