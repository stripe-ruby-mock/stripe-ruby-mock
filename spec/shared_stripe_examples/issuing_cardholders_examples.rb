require 'spec_helper'

shared_examples 'Issuing Cardholders API' do
  let(:params){{
      type: 'virtual',
      name: 'Bo Diddley',
      billing: {
          address: {
              line1: '123 high street',
              city: 'Brooklyn',
              state: 'CA',
              country: 'US',
              postal_code: '11201'
          }
      }
  }}

  describe 'list cardholders' do
    it 'lists all cardholders' do
      c1 = Stripe::Issuing::Cardholder.create(params)
      c2 = Stripe::Issuing::Cardholder.create(params)
      list = Stripe::Issuing::Cardholder.list
      expect(list[:data]).to include(c1,c2)
    end
  end



  context 'update cardholder' do
    it 'updates the cardholder' do
      cardholder = Stripe::Issuing::Cardholder.create(params)
      result = Stripe::Issuing::Cardholder.update(cardholder.id, {status: 'active'})
      expect(result.status).to eq('active')
    end
  end

  context 'create cardholder' do
    it 'creates a cardholder' do
      cardholder = Stripe::Issuing::Cardholder.create(params)
      expect(cardholder.object).to eq('issuing.cardholder')
      expect(cardholder.billing.address.country).to eq('US')
      expect(cardholder.billing.name).to eq('Bo Diddley')
      expect(cardholder).to be_a Stripe::Issuing::Cardholder
      expect(cardholder.id).to match(/ich_/)
    end
    describe 'Errors' do
      context 'missing type' do
        it 'throws error' do
          params.delete(:type)
          expect{Stripe::Issuing::Cardholder.create(params)}.to raise_error(/Missing required param: type/)
        end
      end
      context 'missing name' do
        it 'throws error' do
          params.delete(:name)
          expect{Stripe::Issuing::Cardholder.create(params)}.to raise_error(/Missing required param: name/)
        end
      end
      context 'missing billing' do
        it 'throws error' do
          params.delete(:billing)
          expect{Stripe::Issuing::Cardholder.create(params)}.to raise_error(/Missing required param: billing/)
        end
      end
      context 'missing billing address' do
        it 'throws error' do
          params[:billing].delete(:address)
          expect{Stripe::Issuing::Cardholder.create(params)}.to raise_error(/Missing required param: billing\[address\]/)
        end
      end
      context 'missing billing address line1' do
        it 'throws error' do
          params[:billing][:address].delete(:line1)
          expect{Stripe::Issuing::Cardholder.create(params)}.to raise_error(/Missing required param: billing\[address\]\[line1\]/)
        end
      end
      context 'missing billing address city' do
        it 'throws error' do
          params[:billing][:address].delete(:city)
          expect{Stripe::Issuing::Cardholder.create(params)}.to raise_error(/Missing required param: billing\[address\]\[city\]/)
        end
      end
      context 'missing billing address country' do
        it 'throws error' do
          params[:billing][:address].delete(:country)
          expect{Stripe::Issuing::Cardholder.create(params)}.to raise_error(/Missing required param: billing\[address\]\[country\]/)
        end
      end
      context 'missing billing address state' do
        it 'throws error' do
          params[:billing][:address].delete(:state)
          expect{Stripe::Issuing::Cardholder.create(params)}.to raise_error(/Missing required param: billing\[address\]\[state\]/)
        end
      end
      context 'missing billing address postal code' do
        it 'throws error' do
          params[:billing][:address].delete(:postal_code)
          expect{Stripe::Issuing::Cardholder.create(params)}.to raise_error(/Missing required param: billing\[address\]\[postal_code\]/)
        end
      end
    end
  end


  context 'get cardholder' do
    let(:cardholder) {Stripe::Issuing::Cardholder.create(params.merge(id: 'foo'))}

    it 'retreives an existing cardholder' do
      cardholder = Stripe::Issuing::Cardholder.create(params.merge(id: 'foo'))
      retreived = Stripe::Issuing::Cardholder.retrieve('foo')
      expect(retreived).to eq(cardholder)
    end
    describe 'Errors' do
      it 'throws an error if the cardholder doesnt exist' do
        expect {
          Stripe::Issuing::Cardholder.retrieve('foo')
        }.to raise_error {|e|
          expect(e).to be_a(Stripe::InvalidRequestError)
          expect(e.message).to eq('No such cardholder: foo')
        }
      end
    end
  end


end