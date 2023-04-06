# frozen_string_literal: false

describe TriggerWebhookJob, type: :job do
  subject do
    described_class.perform_now(webhook_endpoint_id)
  end

  let!(:webhook_endpoint) { create(:webhook_endpoint) }
  let(:webhook_endpoint_id) { webhook_endpoint.id }

  describe "#perform" do
    before do
      allow(WebhookEndpoint).to receive(:find)
        .and_return(webhook_endpoint)
      allow(webhook_endpoint).to receive(:trigger_for_all_subscribed_resources)
    end

    it "calls the trigger_for_all_subscribed_resources method of a webhook" do
      expect(WebhookEndpoint).to receive(:find)
        .with(webhook_endpoint_id)
      expect(webhook_endpoint).to receive(:trigger_for_all_subscribed_resources)
      subject
    end
  end
end
