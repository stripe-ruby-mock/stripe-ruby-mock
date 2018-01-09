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
        incorrect_number: add_json_body(["The card number is incorrect", 'number', 'incorrect_number', http_status: 402]),
        invalid_number: add_json_body(["The card number is not a valid credit card number", 'number', 'invalid_number', http_status: 402]),
        invalid_expiry_month: add_json_body(["The card's expiration month is invalid", 'exp_month', 'invalid_expiry_month', http_status: 402]),
        invalid_expiry_year: add_json_body(["The card's expiration year is invalid", 'exp_year', 'invalid_expiry_year', http_status: 402]),
        invalid_cvc: add_json_body(["The card's security code is invalid", 'cvc', 'invalid_cvc', http_status: 402]),
        expired_card: add_json_body(["The card has expired", 'exp_month', 'expired_card', http_status: 402]),
        incorrect_cvc: add_json_body(["The card's security code is incorrect", 'cvc', 'incorrect_cvc', http_status: 402]),
        card_declined: add_json_body(["The card was declined", nil, 'card_declined', http_status: 402]),
        missing: add_json_body(["There is no card on a customer that is being charged.", nil, 'missing', http_status: 402]),
        processing_error: add_json_body(["An error occurred while processing the card", nil, 'processing_error', http_status: 402]),
        card_error: add_json_body(['The card number is not a valid credit card number.', 'number', 'invalid_number', http_status: 402]),
        incorrect_zip: add_json_body(['The zip code you supplied failed validation.', 'address_zip', 'incorrect_zip', http_status: 402])
      }
    end

    def self.get_decline_code(code)
      decline_code_map = {
        card_declined: 'do_not_honor',
        missing: nil
      }
      decline_code_map.default = code.to_s

      code_key = code.to_sym
      decline_code_map[code_key]
    end

    def self.add_json_body(error_values)
      error_keys = [:message, :param, :code]

      json_hash = Hash[error_keys.zip error_values]
      json_hash[:type] = 'card_error'
      json_hash[:decline_code] = get_decline_code(json_hash[:code])

      error_values.last.merge!(json_body: { error: json_hash }, http_body: { error: json_hash })

      error_values
    end
  end
end
