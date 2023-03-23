# frozen_string_literal: false

describe WebhookJob, type: :job do
  stub_sentry_events

  describe "#perform" do
    let(:payload) { "{}" }
    let(:webhook_endpoint) { create(:webhook_endpoint, secret: "bla", target_url: "https://example.com/rdv-s-endpoint") }

    before do
      stub_request(:post, "https://example.com/rdv-s-endpoint").and_return({ status: 500, body: "ERROR" })
    end

    context "when running the job for the first time" do
      it "retries and sends info to Sentry" do
        expect do
          described_class.perform_now(payload, webhook_endpoint.id)
        end.to have_enqueued_job(described_class).with(payload, webhook_endpoint.id).on_queue(:webhook_retries)

        expect(sentry_events.last.exception.values.first.value).to match(/Webhook-Failure\s\(ERROR\):/)
        expect(sentry_events.last.exception.values.first.type).to eq("OutgoingWebhookError")
      end
    end

    context "when running the job for the 10th time" do
      before do
        allow_any_instance_of(described_class).to receive(:executions_for).with([OutgoingWebhookError]).and_return(10) # rubocop:disable RSpec/AnyInstance
      end

      it "does not retry but sends notification to Sentry" do
        expect do
          expect do
            described_class.perform_now(payload, webhook_endpoint.id)
          end.to raise_error(OutgoingWebhookError)
        end.not_to have_enqueued_job

        expect(sentry_events.size).to eq(1)
        expect(sentry_events.last.exception.values.first.value).to match(/Webhook-Failure\s\(ERROR\):/)
        expect(sentry_events.last.exception.values.first.type).to eq("OutgoingWebhookError")
      end
    end
  end

  describe ".false_negative_from_drome?" do
    it "return false when the body is 'ERROR'" do
      body = "ERROR"
      expect(described_class.false_negative_from_drome?(body)).to eq(false)
    end

    it "return false when the message is 'Another error message'" do
      body = "{\"message\": \"Another error message\"}"
      expect(described_class.false_negative_from_drome?(body)).to eq(false)
    end

    [
      "{\"message\": \"Can't update appointment.\"}",
      "{\"message\": \"Appointment id doesn't exist\"}",
      "{\"message\": \"Appointment already deleted\"}",
      "{\"message\": \"Can't create appointment.\"}",
    ].each do |returned_message|
      it "return true when message is `#{returned_message}`" do
        expect(described_class.false_negative_from_drome?(returned_message)).to eq(true)
      end
    end
  end
end
