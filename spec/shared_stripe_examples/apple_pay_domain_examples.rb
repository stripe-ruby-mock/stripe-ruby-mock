require 'spec_helper'

shared_examples 'ApplePayDomain API' do
  context 'create apple pay domain' do
    let (:apple_pay_domain) { stripe_helper.create_apple_pay_domain }

    it 'creates a stripe apple pay domain', live: true do
      expect(apple_pay_domain).not_to be_nil
    end

    it 'stores a created stripe apple pay domain in memory' do
      apple_pay_domain

      data = test_data_source(:apple_pay_domains)

      expect(data[apple_pay_domain.id]).not_to be_nil
    end

    it 'fails when a domain is created with a domain_name' do
      expect {
        Stripe::ApplePayDomain.create(domain_name: nil)
      }.to raise_error { |e|
        expect(e).to be_a(Stripe::InvalidRequestError)
      }
    end
  end

  context 'retrieve apple pay domain' do
    let (:apple_pay_domain1) { stripe_helper.create_apple_pay_domain }

    it 'retrieves a stripe apple pay domain' do
      apple_pay_domain1

      apple_pay_domain = Stripe::ApplePayDomain.retrieve(apple_pay_domain1.id)

      expect(apple_pay_domain.id).to eq(apple_pay_domain.id)
    end

    it 'retrieves all apple pay domains' do
      stripe_helper.delete_all_apple_pay_domains

      apple_pay_domain1

      all = Stripe::ApplePayDomain.list

      expect(all.count).to eq(2)
    end

    it 'cannot retrieve an apple pay domain that doesnt exist' do
      expect {
        Stripe::ApplePayDomain.retrieve('nope')
      }.to raise_error { |e|
        expect(e).to be_a(Stripe::InvalidRequestError)
      }
    end
  end

  context 'delete apple pay domain' do
    it 'deletes an apple pay domain' do
      original = stripe_helper.create_apple_pay_domain
      apple_pay_domain = Stripe::ApplePayDomain.retrieve(original.id)

      apple_pay_domain.delete

      expect {
        Stripe::ApplePayDomain.retrieve(apple_pay_domain.id)
      }.to raise_error { |x|
        expect(e).to be_a(Stripe::InvalidRequestError)
      }
    end
  end
end