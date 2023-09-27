# frozen_string_literal: false

describe WebhookJob, type: :job do
  stub_sentry_events

  describe "#perform" do
    let(:payload) { "{}" }
    let(:webhook_endpoint) { create(:webhook_endpoint, secret: "bla", target_url: "https://example.com/rdv-s-endpoint") }

    it "retries and notifies Sentry on the 3rd and 10th tries" do
      stub_request(:post, "https://example.com/rdv-s-endpoint").and_return({ status: 500, body: "ERROR" })

      described_class.perform_later(payload, webhook_endpoint.id)

      expect(enqueued_jobs.first["executions"]).to eq(0)

      # first execution, error is not logged
      perform_enqueued_jobs
      expect(enqueued_jobs.first["executions"]).to eq(1)
      expect(sentry_events).to be_empty

      # retry twice, nothing logged
      2.times { perform_enqueued_jobs }
      expect(enqueued_jobs.first["executions"]).to eq(3)
      expect(sentry_events).to be_empty

      # retry again, the error is logged
      perform_enqueued_jobs
      expect(sentry_events.last.exception.values.last.type).to eq("OutgoingWebhookError")

      # reset sentry stubs
      # teardown_sentry_test
      # setup_sentry_test

      # retry again, no more errors
      5.times { perform_enqueued_jobs }

      # 10th execution, error is logged
      perform_enqueued_jobs
      expect(sentry_events.last.exception.values.last.type).to eq("OutgoingWebhookError")
    end

    it "retries with a lower priority" do
      stub_request(:post, "https://example.com/rdv-s-endpoint").and_return({ status: 500, body: "ERROR" })
      described_class.perform_later(payload, webhook_endpoint.id)

      perform_enqueued_jobs
      expect(enqueued_jobs.first["priority"]).to eq(-20)
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
