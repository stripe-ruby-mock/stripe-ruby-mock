module StripeMock
  class Instance

    attr_reader :charges, :customers

    def initialize
      @customers = {}
      @charges = {}
      @id_counter = 0
    end

    def mock_request(method, url, api_key, params={}, headers={})
      return {} if method == :xtest

      # Ordered from most specific to least specific
      case "#{method} #{url}"

      when 'post /v1/charges'
        id = new_id
        charges[id] = Data.test_charge(params.merge :id => id)

      when 'post /v1/customers'
        id = new_id
        customers[id] = Data.test_customer(params.merge :id => id)

      when 'post /v1/invoiceitems'
        Data.test_invoice(params)

      when %r{post /v1/customers/(.*)/subscription}
        Data.test_subscription(params[:plan])

      when %r{post /v1/customers/(.*)}
        customers[$1] ||= Data.test_customer(:id => $1)
        customers[$1].merge!(params)

      when %r{get /v1/charges/(.*)}
        charges[$1] ||= Data.test_charge(:id => $1)

      when %r{get /v1/customers/(.*)}
        customers[$1] ||= Data.test_customer(:id => $1)

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
