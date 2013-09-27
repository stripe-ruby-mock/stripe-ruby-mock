module StripeMock

  def self.generate_bank_token(bank_params)
    if @state == 'local'
      instance.generate_bank_token(bank_params)
    elsif @state == 'remote'
      client.generate_bank_token(bank_params)
    else
      raise UnstartedStateError
    end
  end

end