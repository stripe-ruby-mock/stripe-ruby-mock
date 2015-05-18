module StripeMock
  class Instance

    include StripeMock::RequestHandlers::Helpers
    include StripeMock::RequestHandlers::ParamValidators

    # Handlers are ordered by priority
    @@handlers = []

    def self.add_handler(route, name)
      @@handlers << {
        :route => %r{^#{route}$},
        :name => name
      }
    end

    def self.handler_for_method_url(method_url)
      @@handlers.find {|h| method_url =~ h[:route] }
    end

    include StripeMock::RequestHandlers::Accounts
    include StripeMock::RequestHandlers::Charges
    include StripeMock::RequestHandlers::Cards
    include StripeMock::RequestHandlers::Sources
    include StripeMock::RequestHandlers::Subscriptions # must be before Customers
    include StripeMock::RequestHandlers::Customers
    include StripeMock::RequestHandlers::Coupons
    include StripeMock::RequestHandlers::Events
    include StripeMock::RequestHandlers::Invoices
    include StripeMock::RequestHandlers::InvoiceItems
    include StripeMock::RequestHandlers::Plans
    include StripeMock::RequestHandlers::Recipients
    include StripeMock::RequestHandlers::Transfers
    include StripeMock::RequestHandlers::Tokens


    attr_reader :accounts, :bank_tokens, :charges, :coupons, :customers, :events,
                :invoices, :invoice_items, :plans, :recipients, :transfers, :subscriptions

    attr_accessor :error_queue, :debug

    def initialize
      @accounts = {}
      @bank_tokens = {}
      @card_tokens = {}
      @customers = {}
      @charges = {}
      @coupons = {}
      @events = {}
      @invoices = {}
      @invoice_items = {}
      @plans = {}
      @recipients = {}
      @transfers = {}
      @subscriptions = {}

      @debug = false
      @error_queue = ErrorQueue.new
      @id_counter = 0
      @balance_transaction_counter = 0

      # This is basically a cache for ParamValidators
      @base_strategy = TestStrategies::Base.new
    end

    def mock_request(method, url, api_key, params={}, headers={}, api_base_url=nil)
      return {} if method == :xtest

      api_key ||= Stripe.api_key

      # Ensure params hash has symbols as keys
      params = Stripe::Util.symbolize_names(params)

      method_url = "#{method} #{url}"

      if handler = Instance.handler_for_method_url(method_url)
        if @debug == true
          puts "- - - - " * 8
          puts "[StripeMock req]::#{handler[:name]} #{method} #{url}"
          puts "                  #{params}"
        end

        if mock_error = @error_queue.error_for_handler_name(handler[:name])
          @error_queue.dequeue
          raise mock_error
        else
          res = self.send(handler[:name], handler[:route], method_url, params, headers)
          puts "           [res]  #{res}" if @debug == true
          [res, api_key]
        end
      else
        puts "[StripeMock] Warning : Unrecognized endpoint + method : [#{method} #{url}]"
        puts "[StripeMock] params: #{params}" unless params.empty?
        [{}, api_key]
      end
    end

    def generate_webhook_event(event_data)
      event_data[:id] ||= new_id 'evt'
      @events[ event_data[:id] ] = symbolize_names(event_data)
    end

    private

    def assert_existence(type, id, obj, message=nil)
      if obj.nil?
        msg = message || "No such #{type}: #{id}"
        raise Stripe::InvalidRequestError.new(msg, type.to_s, 404)
      end
      obj
    end

    def new_id(prefix)
      # Stripe ids must be strings
      "#{StripeMock.global_id_prefix}#{prefix}_#{@id_counter += 1}"
    end

    def new_balance_transaction(prefix)
      # balance transaction ids must be strings
      "#{StripeMock.global_id_prefix}#{prefix}_#{@balance_transaction_counter += 1}"
    end

    def symbolize_names(hash)
      Stripe::Util.symbolize_names(hash)
    end

  end
end
