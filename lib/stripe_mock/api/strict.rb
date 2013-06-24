module StripeMock

  def self.toggle_strict(toggle)
    if @state == 'local'
      @instance.strict = toggle
    elsif @state == 'remote'
      @client.set_server_strict(toggle)
    end
  end

end
