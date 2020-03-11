require 'spec_helper'

shared_examples 'Person API' do

  describe 'list people' do
    let(:account_1){Stripe::Account.create(id: 'test_account', type: 'custom', country: "US")}
    let(:account_2){Stripe::Account.create(id: 'test_account2', type: 'custom', country: "US")}
    let!(:p1){Stripe::Account.create_person(account_1.id, {})}
    let!(:p2){Stripe::Account.create_person(account_1.id, {})}
    let!(:p3){Stripe::Account.create_person(account_2.id, {})}
    it 'only lists the people for the account' do
      list = Stripe::Account.list_persons( account_1.id,{} )
      expect(list[:data]).to include(p1,p2)
      expect(list[:data]).not_to include(p3)
    end
  end

  context 'delete a person' do
    let(:account){Stripe::Account.create(id: 'test_account', type: 'custom', country: "US")}
    it 'deletes the person' do
      person = Stripe::Account.create_person(account.id, {})
      result = Stripe::Account.delete_person(account.id, person.id)
      expect(result.deleted).to eq(true)
    end

    describe 'Errors' do
      it 'throws an error if the person doesnt exist' do
        expect {
          Stripe::Account.retrieve_person('foo', 'bar')
        }.to raise_error {|e|
          expect(e).to be_a(Stripe::InvalidRequestError)
          expect(e.message).to eq('No such person: bar')
        }
      end
      it 'throws an error if the person exists but not on the account specified'  do
        person = Stripe::Account.create_person(account.id, {})
        expect {
          Stripe::Account.retrieve_person('foo', person.id)
        }.to raise_error {|e|
          expect(e).to be_a(Stripe::InvalidRequestError)
          expect(e.message).to eq("No such person: #{person.id}")
        }
      end
    end
  end

  context 'update person' do
    it 'updates the person' do
      account = Stripe::Account.create(id: 'test_account', type: 'custom', country: "US")
      person = Stripe::Account.create_person(account.id, {})
      params = {address: {line1: '123 easy street'}, first_name: "tilda", last_name: 'Swinton', relationship:{director: true}}
      result = Stripe::Account.update_person(account.id, person.id, params)
      expect(result.first_name).to eq('tilda')
      expect(result.last_name).to eq('Swinton')
      expect(result.address.line1).to eq('123 easy street')
      expect(result.relationship.director).to eq(true)
    end
    describe 'Errors' do
      context 'an ssn that isnt 4 digits' do
        let(:account) {Stripe::Account.create(id: 'test_account', type: 'custom', country: "US")}
        let(:person){Stripe::Account.create_person(account.id, {})}
        it 'throws an error when its the wrong number of digits' do
          expect {
            Stripe::Account.update_person(account.id, person.id, { ssn_last_4: '99' })
          }.to raise_error {|e|
            expect(e).to be_a(Stripe::InvalidRequestError)
            expect(e.message).to eq('Invalid SSN last 4. SSN last 4 must be exactly four digits')
          }
        end
        it 'throws an error when letters' do
          expect {
            Stripe::Account.update_person(account.id, person.id, { ssn_last_4: 'aaaa' })
          }.to raise_error {|e|
            expect(e).to be_a(Stripe::InvalidRequestError)
            expect(e.message).to eq('Invalid SSN last 4. SSN last 4 must be exactly four digits')
          }
        end
      end
    end
  end

  context 'create person' do
    it 'creates a person' do
      account = Stripe::Account.create(id: 'test_account', type: 'custom', country: "US")
      person = Stripe::Account.create_person(account.id, {})
      expect(person.object).to eq('person')
      expect(person.address.country).to eq('US')
      expect(person.ssn_last_4_provided).to eq(false)
      expect(person).to be_a Stripe::Person
      expect(person.id).to match(/person_/)
    end
    describe 'Errors' do
      context 'an ssn that isnt 4 digits' do
        let(:account) {Stripe::Account.create(id: 'test_account', type: 'custom', country: "US")}
        it 'throws an error when its the wrong number of digits' do
          expect {
            Stripe::Account.create_person(account.id, { ssn_last_4: '99' })
          }.to raise_error {|e|
            expect(e).to be_a(Stripe::InvalidRequestError)
            expect(e.message).to eq('Invalid SSN last 4. SSN last 4 must be exactly four digits')
          }
        end
        it 'throws an error when letters' do
          expect {
            Stripe::Account.create_person(account.id, { ssn_last_4: 'aaaa' })
          }.to raise_error {|e|
            expect(e).to be_a(Stripe::InvalidRequestError)
            expect(e.message).to eq('Invalid SSN last 4. SSN last 4 must be exactly four digits')
          }
        end
      end
    end
  end


  context 'get person' do
    let(:account) {Stripe::Account.create(id: 'test_account', type: 'custom', country: "US")}

    it 'retreives an existing person' do
      person = Stripe::Account.create_person(account.id, {})
      retreived_person = Stripe::Account.retrieve_person(account.id, person.id)
      expect(retreived_person.id).to eq person.id
      expect(retreived_person.account).to eq account.id
    end
    describe 'Errors' do
      it 'throws an error if the person doesnt exist' do
        expect {
          Stripe::Account.retrieve_person('foo', 'bar')
        }.to raise_error {|e|
          expect(e).to be_a(Stripe::InvalidRequestError)
          expect(e.message).to eq('No such person: bar')
        }
      end
      it 'throws an error if the person exists but not on the account specified'  do
        person = Stripe::Account.create_person(account.id, {})
        expect {
          Stripe::Account.retrieve_person('foo', person.id)
        }.to raise_error {|e|
          expect(e).to be_a(Stripe::InvalidRequestError)
          expect(e.message).to eq("No such person: #{person.id}")
        }
      end
    end
  end


end