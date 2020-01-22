module StripeMock
  module RequestHandlers
    module Persons
      def Persons.included(klass)
        klass.add_handler 'post /v1/accounts/(.*)/persons', :create_person
      end

      def create_person(route, method_url, params, headers)
        route =~ method_url
        account = assert_existence :account, $1, accounts[$1]
        persons[params[:id]] ||= Data.mock_person(account, params)
      end


    end
  end
end