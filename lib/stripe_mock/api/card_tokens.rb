module StripeMock

  def self.generate_card_token(card_params = {})
    case @state
      when 'local'
puts "local -> instance.generate_card_token"
      instance.generate_card_token(card_params)
    when 'remote'
puts "remote -> client.generate_card_token"
      client.generate_card_token(card_params)
    else
      raise UnstartedStateError
    end
  end

  def self.renew_subscriptions(subscription_list = [])
    case @state
      when 'local'
        instance.generate_card_token(card_params)
      when 'remote'
        client.generate_card_token(card_params)
      else
        raise UnstartedStateError
    end
  end
end
