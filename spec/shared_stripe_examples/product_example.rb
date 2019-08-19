require 'spec_helper'

shared_examples 'Product API' do
  it 'creates a product' do
    product = Stripe::Product.create(
      name: 'my awesome product',
      type: 'service'
    )

    expect(product.name).to eq 'my awesome product'
    expect(product.type).to eq 'service'
  end

  it 'retrieves a product' do
    Stripe::Product.create(
      id:   'test_prod_1',
      name: 'my awesome product',
      type: 'service'
    )

    product = Stripe::Product.retrieve('test_prod_1')

    expect(product.name).to eq 'my awesome product'
    expect(product.type).to eq 'service'
  end

  it 'updates a product' do
    Stripe::Product.create(
      id:   'test_prod_1',
      name: 'my awesome product',
      type: 'service'
    )

    Stripe::Product.update('test_prod_1', name: 'my lame product')

    product = Stripe::Product.retrieve('test_prod_1')

    expect(product.name).to eq 'my lame product'
  end

  it 'lists all products' do
    2.times do |n|
      Stripe::Product.create(
        name: "product #{n}",
        type: 'service'
      )
    end

    products = Stripe::Product.list

    expect(products.map(&:name)).to match_array ['product 0', 'product 1']
  end

  it 'destroys a product', live: true do
    Stripe::Product.create(
      id:   'test_prod_1',
      name: 'my awesome product',
      type: 'service'
    )

    Stripe::Product.delete('test_prod_1')

    expect { Stripe::Product.retrieve('test_prod_1') }. to raise_error(Stripe::InvalidRequestError)
  end
end
