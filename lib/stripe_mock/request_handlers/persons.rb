module StripeMock
  module RequestHandlers
    module Persons
      def Persons.included(klass)
        klass.add_handler 'post /v1/accounts/([^/]*)/persons', :create_person
        klass.add_handler 'get /v1/accounts/([^/]*)/persons/([^/]*)', :get_person
        klass.add_handler 'post /v1/accounts/([^/]*)/persons/([^/]*)', :update_person
        klass.add_handler 'delete /v1/accounts/([^/]*)/persons/([^/]*)', :delete_person
        klass.add_handler 'get /v1/accounts/([^/]*)/persons', :list_persons
      end


      def list_persons(route, method_url, params, _headers)
        route =~ method_url
        account =  assert_existence :account, $1, accounts[$1]
        list = persons.select{|_key, obj| obj[:account]== account[:id]}
        Data.mock_list_object(list.values, params)
      end

      def delete_person(route, method_url, params, _headers)
        route =~ method_url
        assert_person_exists($2,$1)
        persons[$2] = {
            id: persons[$2][:id],
            deleted: true
        }
      end

      def create_person(route, method_url, params, _headers)
        params[:id] ||= new_id('person')
        route =~ method_url
        assert_ssn_correct(params)
        account = assert_existence :account, $1, accounts[$1]
        persons[params[:id]] ||= Data.mock_person(account, params)
      end

      def get_person(route, method_url, _params, _headers)
        route =~ method_url
        assert_person_exists($2,$1)
      end

      def update_person(route, method_url, params, _headers)
        route =~ method_url
        person = assert_person_exists($2,$1)
        assert_ssn_correct(params)
        person.merge!(params)
        person
      end

      private

      def assert_person_exists(person_id, account_id)
        person = persons[person_id]
        if person.nil? || person[:account] != account_id
          raise Stripe::InvalidRequestError.new("No such person: #{person_id}", 'person', http_status: 404)
        end
        person
      end

      def assert_ssn_correct(params)
        if !params[:ssn_last_4].nil? && params[:ssn_last_4].match(/^\d{4}$/).nil?
          raise Stripe::InvalidRequestError.new('Invalid SSN last 4. SSN last 4 must be exactly four digits', nil, http_status: 400)
        end
      end
    end
  end
end
