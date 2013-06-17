
def require_stripe_examples
  require 'shared_stripe_examples/charges'
  require 'shared_stripe_examples/customers'
  require 'shared_stripe_examples/error_mocks'
  require 'shared_stripe_examples/invoice_items'
  require 'shared_stripe_examples/plans'
end

def it_behaves_like_stripe(&block)
  it_behaves_like 'Charge API', &block
  it_behaves_like 'Customer API', &block
  it_behaves_like 'Invoice Item API', &block
  it_behaves_like 'Plan API', &block
  it_behaves_like 'Stripe Error Mocking', &block
end
