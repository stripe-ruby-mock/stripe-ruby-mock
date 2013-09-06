module StripeMock

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