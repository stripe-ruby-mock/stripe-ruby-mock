module StripeMock

  @default_pid_path = './stripe-mock-server.pid'
  @default_log_path = './stripe-mock-server.log'

  def self.default_server_pid_path; @default_pid_path; end
  def self.default_server_pid_path=(new_path)
    @default_pid_path = new_path
  end


  def self.spawn_server(opts={})
    pid_path = opts[:pid_path] || @default_pid_path
    log_path = opts[:log_path] || @default_log_path

    Dante::Runner.new('stripe-mock-server').execute(
      :daemonize => true, :pid_path => pid_path, :log_path => log_path
    ){
      StripeMock::Server.start_new(opts)
    }
    at_exit { kill_server(pid_path) }
  end

  def self.kill_server(pid_path=nil)
    puts "Y WE KILL NO"
    path = pid_path || @default_pid_path
    Dante::Runner.new('stripe-mock-server').execute(:kill => true, :pid_path => path)
  end

end
