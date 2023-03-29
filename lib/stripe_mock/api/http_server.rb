require 'capybara_discoball'
require 'sinatra/base'
require 'sinatra/cors'
require 'sinatra/multi_route'

module StripeMock
  def self.start_http
    StripeMock.start
    url = Capybara::Discoball.spin(StripeMock::HttpServer::App)
    StripeMock::HttpServer::App.instance = StripeMock.instance
    StripeMock::HttpServer::App.url = url
  end

  class HttpServer
    class App < Sinatra::Base
      register Sinatra::MultiRoute
      register Sinatra::Cors

      def self.url=(url)
        @@url = url
      end

      def self.url
        @@url
      end

      def self.instance=(instance)
        @@instance = instance
      end

      before do
        headers['Access-Control-Allow-Origin'] = '*'
        headers['Access-Control-Allow-Methods'] = 'POST'
        headers['Access-Control-Allow-Headers'] = 'Authorization, Content-Type'
      end

      route :get, :post, "/*" do
        begin
          method = request.request_method.downcase
          url = request.path
          api_key = request.env['HTTP_AUTHORIZATION']
          resp = @@instance.mock_request(method, url, api_key: api_key, params: params)
          status 200
          content_type :json
          {
            #"data" => {
              **resp.first.data
            #}
          }.to_json
        rescue Stripe::CardError => e
          status 402
          content_type :json
          {
            #"data" => {
            "error" => {
              "message" => e.message
            }
            #}
          }.to_json
        end
      end
    end
  end
end
