module StripeMock
  module Methods

    def self.mock_request(method, url, api_key, params={}, headers={})
      return {} if method == :xtest

      # Ordered from most specific to least specific
      case "#{method} #{url}"
      when 'post /v1/customers'
        Data.test_customer(params)
      when 'post /v1/invoiceitems'
        Data.test_invoice(params)
      when %r{post /v1/customers/(.*)/subscription}
        Data.test_subscription(params[:plan])
      when %r{get /v1/customers/(.*)}
        Data.test_customer :id => $1
      else
        puts "WARNING: Unrecognized method + url: [#{method} #{url}]"
        puts " params: #{params}"
        {}
      end
    end

  end
end
