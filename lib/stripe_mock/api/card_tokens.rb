module StripeMock

  def self.generate_card_token(card_params)
    if @state == 'local'
      instance.generate_card_token(card_params)
    elsif @state == 'remote'
      client.generate_card_token(card_params)
    else
      raise UnstartedStateError
    end
  end

  def self.generate_recipient_token(recipient_params)
    if @state == 'local'
      instance.generate_recipient_token(recipient_params)
    elsif @state == 'remote'
      client.generate_recipient_token(recipient_params)
    else
      raise UnstartedStateError
    end
  end
end
