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

    it "doesnt throw exception when drome serveur can't update appointment" do
      payload = "{}"
      webhook_endpoint = create(:webhook_endpoint, secret: "bla", target_url: "https://example.com/rdv-s-endpoint")

      stub_request(:post, "https://example.com/rdv-s-endpoint").and_return({ status: 500, body: "{\"message\": \"Can't update appointment.\"}" })

      expect do
        described_class.perform_now(payload, webhook_endpoint.id)
      end.not_to raise_error
    end

    it "doesnt throw exception when appointment id doesn't exist" do
      payload = "{}"
      webhook_endpoint = create(:webhook_endpoint, secret: "bla", target_url: "https://example.com/rdv-s-endpoint")

      stub_request(:post, "https://example.com/rdv-s-endpoint").and_return({ status: 500, body: "{\"message\": \"Appointment id doesn't exist.\"}" })

      expect do
        described_class.perform_now(payload, webhook_endpoint.id)
      end.not_to raise_error
    end

    it "doesnt throw exception when appointment already deleted" do
      payload = "{}"
      webhook_endpoint = create(:webhook_endpoint, secret: "bla", target_url: "https://example.com/rdv-s-endpoint")

      stub_request(:post, "https://example.com/rdv-s-endpoint").and_return({ status: 500, body: "{\"message\": \"Appointment already deleted.\"}" })

      expect do
        described_class.perform_now(payload, webhook_endpoint.id)
      end.not_to raise_error
    end
  end
end
