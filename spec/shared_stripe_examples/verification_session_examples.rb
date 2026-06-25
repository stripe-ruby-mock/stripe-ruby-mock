require "spec_helper"

shared_examples "Verification Session API" do
  it "creates a verification session" do
    verification_session = Stripe::Identity::VerificationSession.create(
      type: 'document',
      return_url: 'https://example.com/return',
      cancel_url: 'https://example.com/cancel'
    )

    expect(verification_session.id).to match(/^test_vs_/)
    expect(verification_session.object).to eq('identity.verification_session')
    expect(verification_session.type).to eq('document')
    expect(verification_session.status).to eq('requires_input')
    expect(verification_session.return_url).to eq('https://example.com/return')
    expect(verification_session.cancel_url).to eq('https://example.com/cancel')
    expect(verification_session.url).to match(/^https:\/\/verify\.stripe\.com\/start\//)
  end

  it "creates a verification session with id_number type" do
    verification_session = Stripe::Identity::VerificationSession.create(
      type: 'id_number',
      return_url: 'https://example.com/return'
    )

    expect(verification_session.type).to eq('id_number')
    expect(verification_session.status).to eq('requires_input')
  end

  it "creates a verification session with custom options" do
    verification_session = Stripe::Identity::VerificationSession.create(
      type: 'document',
      return_url: 'https://example.com/return',
      options: {
        document: {
          allowed_types: ['passport'],
          require_id_number: true,
          require_live_capture: true
        }
      }
    )

    expect(verification_session.options[:document][:allowed_types]).to eq(['passport'])
    expect(verification_session.options[:document][:require_id_number]).to eq(true)
    expect(verification_session.options[:document][:require_live_capture]).to eq(true)
  end

  it "creates a verification session with metadata" do
    verification_session = Stripe::Identity::VerificationSession.create(
      type: 'document',
      return_url: 'https://example.com/return',
      metadata: {
        order_id: '12345',
        user_id: 'user_123'
      }
    )

    expect(verification_session.metadata[:order_id]).to eq('12345')
    expect(verification_session.metadata[:user_id]).to eq('user_123')
  end

  context "when creating a verification session" do
    it "requires type parameter" do
      expect do
        Stripe::Identity::VerificationSession.create(
          return_url: 'https://example.com/return'
        )
      end.to raise_error(Stripe::InvalidRequestError, /type/i)
    end

    it "validates type values" do
      expect do
        Stripe::Identity::VerificationSession.create(
          type: 'invalid_type',
          return_url: 'https://example.com/return'
        )
      end.to raise_error(Stripe::InvalidRequestError, /Invalid type: must be one of document, id_number/)
    end
  end

  context "retrieve a verification session" do
    let(:verification_session1) { stripe_helper.create_verification_session }

    it "can be retrieved by id" do
      verification_session1

      verification_session = Stripe::Identity::VerificationSession.retrieve(verification_session1.id)

      expect(verification_session.id).to eq(verification_session1.id)
      expect(verification_session.object).to eq('identity.verification_session')
    end

    it "cannot retrieve a verification session that doesn't exist" do
      expect { Stripe::Identity::VerificationSession.retrieve("nope") }.to raise_error { |e|
        expect(e).to be_a Stripe::InvalidRequestError
        expect(e.param).to eq("verification_session")
        expect(e.http_status).to eq(404)
      }
    end
  end

  context "list verification sessions" do
    it "can list verification sessions" do
      verification_session1 = stripe_helper.create_verification_session
      verification_session2 = stripe_helper.create_verification_session(type: 'id_number')

      list = Stripe::Identity::VerificationSession.list

      expect(list.object).to eq('list')
      expect(list.data.count).to eq(2)
      expect(list.data.map(&:id)).to include(verification_session1.id, verification_session2.id)
    end
  end

  context "cancel a verification session" do
    let(:verification_session) { stripe_helper.create_verification_session }

    it "can cancel a verification session" do
      canceled_session = verification_session.cancel

      expect(canceled_session.status).to eq('canceled')
      expect(canceled_session.canceled_at).to_not be_nil
    end

    it "cannot cancel a verification session that doesn't exist" do
      expect do
        Stripe::Identity::VerificationSession.retrieve("nope").cancel
      end.to raise_error(Stripe::InvalidRequestError)
    end
  end

  context "redact a verification session" do
    let(:verification_session) { stripe_helper.create_verification_session }

    it "can redact a verification session" do
      redacted_session = verification_session.redact

      expect(redacted_session.redaction[:status]).to eq('processing')
    end

    it "cannot redact a verification session that doesn't exist" do
      expect do
        Stripe::Identity::VerificationSession.retrieve("nope").redact
      end.to raise_error(Stripe::InvalidRequestError)
    end
  end
end 