# frozen_string_literal: true

describe WebhookDeliverable, type: :concern do
  include ActiveJob::TestHelper

  let!(:organisation) { create(:organisation) }
  let!(:webhook_endpoint) do
    create(
      :webhook_endpoint,
      organisation: organisation,
      subscribed_events: {
        "rdv" => %w[created updated destroyed],
        "absence" => %w[created updated destroyed],
        "plage_ouverture" => %w[created updated destroyed]
      }
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
    context "when the webhook endpoint is subscribed to the model events" do
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

    context "when the webhook endpoint is not subscribed to the model events" do
      let!(:webhook_endpoint) do
        create(
          :webhook_endpoint,
          organisation: organisation,
          subscribed_events: {
            "absence" => %w[created updated destroyed],
            "plage_ouverture" => %w[created updated destroyed]
          }
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

    context "when the webhook endpoint is subscribed in some model events but not all" do
      let!(:webhook_endpoint) do
        create(
          :webhook_endpoint,
          organisation: organisation,
          subscribed_events: {
            "rdv" => %w[created updated],
            "absence" => %w[created updated destroyed],
            "plage_ouverture" => %w[created updated destroyed]
          }
        )
      end

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

      it "does not notify on deletion" do
        expect(WebhookJob).not_to receive(:perform_later)
        rdv.destroy
      end
    end
  end
end
