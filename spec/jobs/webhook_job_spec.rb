# frozen_string_literal: false

describe WebhookJob, type: :job do
  describe "#perform" do
    it "raises OutgoingWebhookError error with the correct error message" do
      payload = "{}"
      webhook_endpoint = create(:webhook_endpoint, secret: "bla", target_url: "https://example.com/rdv-s-endpoint")

      stub_request(:post, "https://example.com/rdv-s-endpoint").and_return({ status: 500, body: "ERROR" })

      expect do
        described_class.perform_now(payload, webhook_endpoint.id)
      end.to raise_error(OutgoingWebhookError, /Webhook-Failure\s\(ERROR\):/)
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
