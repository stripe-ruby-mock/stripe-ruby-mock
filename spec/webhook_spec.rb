require 'spec_helper'

describe 'Webhook Generation' do

  it "matches the list of webhooks with the folder of fixtures" do
    events = StripeMock::Webhooks.event_list.to_set
    file_names = Dir['./lib/stripe_mock/webhook_fixtures/*'].map {|f| File.basename(f, '.json')}.to_set
    # The reason we take the difference instead of compare equal is so
    # that a missing event name will show up in the test failure report.
    expect(events - file_names).to eq(Set.new)
    expect(file_names - events).to eq(Set.new)
  end


  it "first looks in spec/fixtures/stripe_webhooks/ for fixtures by default" do
    event = StripeMock.mock_webhook_event('account.updated')
    expect(event).to be_a(Stripe::Event)
    expect(event.id).to eq('evt_123')
    expect(event.type).to eq('account.updated')
  end

  it "allows non-standard event names in the project fixture folder" do
    expect {
      event = StripeMock.mock_webhook_event('custom.account.updated')
    }.to_not raise_error
  end

  it "allows configuring the project fixture folder" do
    StripeMock.webhook_fixture_path = './spec/_dummy/webhooks/'
    expect(StripeMock.webhook_fixture_path).to eq('./spec/_dummy/webhooks/')

    event = StripeMock.mock_webhook_event('dummy.event')
    expect(event.val).to eq('success')
  end

  it "generates an event" do
    event = StripeMock.mock_webhook_event('customer.created')
    expect(event).to be_a(Stripe::Event)
  end

  it "takes a hash and deep merges into the data object" do
    event = StripeMock.mock_webhook_event('customer.created', { :account_balance => 12345 })
    expect(event.data.object.account_balance).to eq(12345)
  end

  it "takes a hash and deep merges arrays in the data object" do
    event = StripeMock.mock_webhook_event('invoice.created', {
      :lines => {
        :data => [
          { :amount => 555,
            :plan => { :id => 'wh_test' }
          }
        ]
      }
    })
    expect(event.data.object.lines.data.first.amount).to eq(555)
    expect(event.data.object.lines.data.first.plan.id).to eq('wh_test')
    # Ensure data from invoice.created.json is still present
    expect(event.data.object.lines.data.first.type).to eq('subscription')
    expect(event.data.object.lines.data.first.plan.currency).to eq('usd')
  end

  it "can generate all events" do
    StripeMock::Webhooks.event_list.each do |event_name|
      expect { StripeMock.mock_webhook_event(event_name) }.to_not raise_error
    end
  end

  it "raises an error for non-existant event types" do
    expect {
      event = StripeMock.mock_webhook_event('cow.bell')
    }.to raise_error StripeMock::UnsupportedRequestError
  end

end
