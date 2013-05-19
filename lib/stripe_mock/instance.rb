module StripeMock
  class Instance

    # Handlers are ordered by priority
    @@handlers = []

    def self.add_handler(route, name)
      @@handlers << {
        :route => %r{^#{route}$},
        :name => name
      }
    end

    include StripeMock::RequestHandlers::Charges
    include StripeMock::RequestHandlers::Customers
    include StripeMock::RequestHandlers::InvoiceItems


    attr_reader :charges, :customers
    attr_accessor :pending_error

    def initialize
      @customers = {}
      @charges = {}
      @id_counter = 0
      @pending_error = nil
    end

    def mock_request(method, url, api_key, params={}, headers={})
      return {} if method == :xtest

      if @pending_error
        raise @pending_error
        @pending_error = nil
      end

      method_url = "#{method} #{url}"
      handler = @@handlers.find {|h| method_url =~ h[:route] }

      if handler
        self.send  handler[:name],  handler[:route], method_url, params, headers
      else
        puts "WARNING: Unrecognized method + url: [#{method} #{url}]"
        puts " params: #{params}"
        {}
      end
    end

    private

    def new_id
      # Stripe ids must be strings
      (@id_counter += 1).to_s
    end

  end
end
