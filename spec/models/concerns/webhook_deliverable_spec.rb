# frozen_string_literal: true

describe WebhookDeliverable, type: :concern do
  include ActiveJob::TestHelper

  let!(:organisation) { create(:organisation) }
  let!(:webhook_endpoint) do
    create(
      :webhook_endpoint,
      organisation: organisation,
      subscriptions: %w[rdv absence plage_ouverture]
    )
  end
  let!(:rdv) { create(:rdv, organisation: organisation) }

  after do
    clear_enqueued_jobs
  end

  RSpec::Matchers.define :json_payload_with_meta do |key, value|
    match do |actual|
      content = ActiveSupport::JSON.decode(actual)
      content["meta"][key] == value
    end
  end

  describe "#send_web_hook" do
    context "when the webhook endpoint is triggered by the model changes" do
      context "on creation" do
        let!(:rdv) { build(:rdv, organisation: organisation) }

        it "notifies the creation" do
          expect(WebhookJob).to receive(:perform_later).with(json_payload_with_meta("event", "created"), webhook_endpoint.id)
          rdv.save
        end
      end

      it "notifies on update" do
        expect(WebhookJob).to receive(:perform_later).with(json_payload_with_meta("event", "updated"), webhook_endpoint.id)
        rdv.update(status: :excused)
      end

      it "notifies on deletion" do
        expect(WebhookJob).to receive(:perform_later).with(json_payload_with_meta("event", "destroyed"), webhook_endpoint.id)
        rdv.destroy
      end
    end

    context "when the webhook endpoint is triggered by the model changes but webhook callbacks are disabled explcitly" do
      context "on creation" do
        let!(:rdv) { build(:rdv, organisation: organisation) }

        it "notifies the creation" do
          expect(WebhookJob).not_to receive(:perform_later)
          rdv.skip_webhooks = true
          rdv.save
        end
      end

      it "notifies on update" do
        expect(WebhookJob).not_to receive(:perform_later)
        rdv.update(status: :excused, skip_webhooks: true)
      end

      it "notifies on deletion" do
        expect(WebhookJob).not_to receive(:perform_later)
        rdv.skip_webhooks = true
        rdv.destroy
      end
    end

    context "when the webhook endpoint is not triggered by the changes" do
      let!(:webhook_endpoint) do
        create(
          :webhook_endpoint,
          organisation: organisation,
          subscriptions: %w[absence plage_ouverture]
        )
      end

      context "on creation" do
        let!(:rdv) { build(:rdv, organisation: organisation) }

        it "does not notify the creation" do
          expect(WebhookJob).not_to receive(:perform_later)
          rdv.save
        end
      end

      it "does not notify on update" do
        expect(WebhookJob).not_to receive(:perform_later)
        rdv.update(status: :excused)
      end

      it "does not notify on deletion" do
        expect(WebhookJob).not_to receive(:perform_later)
        rdv.destroy
      end
    end
  end
end
