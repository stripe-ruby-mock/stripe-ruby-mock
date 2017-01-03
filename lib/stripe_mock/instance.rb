module StripeMock
  class Instance

    include StripeMock::RequestHandlers::Helpers
    include StripeMock::RequestHandlers::ParamValidators

    DUMMY_API_KEY = (0...32).map { (65 + rand(26)).chr }.join.downcase

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
    include StripeMock::RequestHandlers::BalanceTransactions
    include StripeMock::RequestHandlers::Charges
    include StripeMock::RequestHandlers::Cards
    include StripeMock::RequestHandlers::Sources
    include StripeMock::RequestHandlers::Subscriptions # must be before Customers
    include StripeMock::RequestHandlers::Customers
    include StripeMock::RequestHandlers::Coupons
    include StripeMock::RequestHandlers::Disputes
    include StripeMock::RequestHandlers::Events
    include StripeMock::RequestHandlers::Invoices
    include StripeMock::RequestHandlers::InvoiceItems
    include StripeMock::RequestHandlers::Orders
    include StripeMock::RequestHandlers::Plans
    include StripeMock::RequestHandlers::Refunds
    include StripeMock::RequestHandlers::Recipients
    include StripeMock::RequestHandlers::Transfers
    include StripeMock::RequestHandlers::Tokens
    include StripeMock::RequestHandlers::CountrySpec


    attr_reader :accounts, :balance_transactions, :bank_tokens, :charges, :coupons, :customers,
                :disputes, :events, :invoices, :invoice_items, :orders, :plans, :recipients,
                :refunds, :transfers, :subscriptions, :country_spec

    attr_accessor :error_queue, :debug

    def initialize
      @accounts = {}
      @balance_transactions = Data.mock_balance_transactions(['txn_05RsQX2eZvKYlo2C0FRTGSSA','txn_15RsQX2eZvKYlo2C0ERTYUIA', 'txn_25RsQX2eZvKYlo2C0ZXCVBNM', 'txn_35RsQX2eZvKYlo2C0QAZXSWE', 'txn_45RsQX2eZvKYlo2C0EDCVFRT', 'txn_55RsQX2eZvKYlo2C0OIKLJUY', 'txn_65RsQX2eZvKYlo2C0ASDFGHJ', 'txn_75RsQX2eZvKYlo2C0EDCXSWQ', 'txn_85RsQX2eZvKYlo2C0UJMCDET', 'txn_95RsQX2eZvKYlo2C0EDFRYUI'])
      @bank_tokens = {}
      @card_tokens = {}
      @customers = {}
      @charges = {}
      @coupons = {}
      @disputes = Data.mock_disputes(['dp_05RsQX2eZvKYlo2C0FRTGSSA','dp_15RsQX2eZvKYlo2C0ERTYUIA', 'dp_25RsQX2eZvKYlo2C0ZXCVBNM', 'dp_35RsQX2eZvKYlo2C0QAZXSWE', 'dp_45RsQX2eZvKYlo2C0EDCVFRT', 'dp_55RsQX2eZvKYlo2C0OIKLJUY', 'dp_65RsQX2eZvKYlo2C0ASDFGHJ', 'dp_75RsQX2eZvKYlo2C0EDCXSWQ', 'dp_85RsQX2eZvKYlo2C0UJMCDET', 'dp_95RsQX2eZvKYlo2C0EDFRYUI'])
      @events = {}
      @invoices = {}
      @invoice_items = {}
      @orders = {}
      @plans = {}
      @recipients = {}
      @refunds = {}
      @transfers = {}
      @subscriptions = {}
      @country_spec = {}

      @debug = false
      @error_queue = ErrorQueue.new
      @id_counter = 0
      @balance_transaction_counter = 0

      # This is basically a cache for ParamValidators
      @base_strategy = TestStrategies::Base.new
    end

    def mock_request(method, url, api_key, params={}, headers={}, api_base_url=nil)
      return {} if method == :xtest

      api_key ||= (Stripe.api_key || DUMMY_API_KEY)

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

    def new_balance_transaction(prefix, params = {})
      # balance transaction ids must be strings
      id = "#{StripeMock.global_id_prefix}#{prefix}_#{@balance_transaction_counter += 1}"
      amount = params[:amount]
      unless amount.nil?
        # Fee calculation
        params[:fee] ||= (30 + (amount.abs * 0.029).ceil) * (amount > 0 ? 1 : -1)
      end
      @balance_transactions[id] = Data.mock_balance_transaction(params.merge(id: id))
      id
    end

    def symbolize_names(hash)
      Stripe::Util.symbolize_names(hash)
    end

  end
end
