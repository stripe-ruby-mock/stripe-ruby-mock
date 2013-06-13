module StripeMock

  def self.spawn_server(opts={})
    pid_path = opts[:pid_path] || './stripe-mock-server.pid'
    Dante::Runner.new('stripe-mock-server').execute(:daemonize => true, :pid_path => pid_path) {
      StripeMock::Server.start_new(opts)
    }
    at_exit { kill_server(pid_path) }
  end

  def self.kill_server(pid_path='./stripe-mock-server.pid')
    Dante::Runner.new('stripe-mock-server').execute(:kill => true, :pid_path => pid_path)
  end

end
