# frozen_string_literal: false

describe WebhookJob, type: :job do
  describe "#perform" do
    it "raise OutgoingWebhookError" do
      payload = "{}"
      webhook_endpoint = create(:webhook_endpoint, secret: "bla", target_url: "https://example.com/rdv-s-endpoint")

      stub_request(:post, "https://example.com/rdv-s-endpoint").and_return({ status: 500, body: "ERROR" })

      expect do
        described_class.perform_now(payload, webhook_endpoint.id)
      end.to raise_error(OutgoingWebhookError)
    end

    it "raise error with error message in body" do
      payload = "{}"
      webhook_endpoint = create(:webhook_endpoint, secret: "bla", target_url: "https://example.com/rdv-s-endpoint")

      stub_request(:post, "https://example.com/rdv-s-endpoint").and_return({ status: 500, body: "ERROR" })

      begin
        described_class.perform_now(payload, webhook_endpoint.id)
        raise
      rescue OutgoingWebhookError => e
        expect(YAML.safe_load(e.message)["Webhook-Failure"]["body"]).to eq("ERROR")
      end
    end
  end

  describe ".false_negative_from_drome?" do
    it "return false when..." do
      body = "ERROR"
      expect(described_class.false_negative_from_drome?(body)).to eq(false)
    end

    [
      "{\"message\": \"Can't update appointment\"}",
      "{\"message\": \"Appointment id doesn't exist\"}",
      "{\"message\": \"Appointment already deleted\"}"
    ].each do |returned_message|
      it "return true when message is `#{returned_message}`" do
        expect(described_class.false_negative_from_drome?(returned_message)).to eq(true)
      end
    end
  end
end
