RSpec.describe WebhookJob, type: :job do
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
      expect(enqueued_jobs.first["priority"]).to eq(20)
    end

    it "retries on timeout" do
      stub_request(:post, "https://example.com/rdv-s-endpoint").to_timeout
      described_class.perform_later(payload, webhook_endpoint.id)

      perform_enqueued_jobs
      expect(enqueued_jobs.first["executions"]).to eq(1)
    end

    it "fingerprints the error by URL and HTTP status" do
      stub_request(:post, "https://example.com/rdv-s-endpoint").and_return({ status: 500, body: "ERROR" })
      described_class.perform_later(payload, webhook_endpoint.id)

      4.times { perform_enqueued_jobs } # On ne loggue vers Sentry qu'au 4ème retry
      expect(sentry_events.last.fingerprint).to eq(["OutgoingWebhookError", "https://example.com/rdv-s-endpoint", "500"])
    end

    # Le WAF du Pas-de-Calais bloque certaines requêtes et
    # renvoie une réponse en HTML avec un statut 200.
    it "detects WAF blockage that returns a 200" do
      stub_request(:post, "https://example.com/rdv-s-endpoint").and_return({ status: 200, body: "<html><title>Request Rejected</title><body>...</body><html>" })
      described_class.perform_later(payload, webhook_endpoint.id)
      4.times { perform_enqueued_jobs } # On ne loggue vers Sentry qu'au 4ème retry
      expect(sentry_events.last.message).to eq("HTML body in HTTP 200 response in webhook to [https://example.com/rdv-s-endpoint]")
    end
  end

  describe ".false_negative_from_drome?" do
    it "return false when the body is 'ERROR'" do
      body = "ERROR"
      expect(described_class.false_negative_from_drome?(body)).to be(false)
    end

    it "return false when the message is 'Another error message'" do
      body = "{\"message\": \"Another error message\"}"
      expect(described_class.false_negative_from_drome?(body)).to be(false)
    end

    [
      "{\"message\": \"Can't update appointment.\"}",
      "{\"message\": \"Appointment id doesn't exist\"}",
      "{\"message\": \"Appointment already deleted\"}",
      "{\"message\": \"Can't create appointment.\"}",
    ].each do |returned_message|
      it "return true when message is `#{returned_message}`" do
        expect(described_class.false_negative_from_drome?(returned_message)).to be(true)
      end
    end
  end
end
