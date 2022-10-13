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
          expect do
            rdv.save
          end.to have_enqueued_job(WebhookJob).with(json_payload_with_meta("event", "created"), webhook_endpoint.id)
        end
      end

      it "notifies on update" do
        expect do
          rdv.update(status: :excused)
        end.to have_enqueued_job(WebhookJob).with(json_payload_with_meta("event", "updated"), webhook_endpoint.id)
      end

      it "notifies on deletion" do
        expect do
          rdv.destroy
        end.to have_enqueued_job(WebhookJob).with(json_payload_with_meta("event", "destroyed"), webhook_endpoint.id)
      end
    end

    context "when the webhook endpoint is triggered by the model changes but webhook callbacks are disabled explicitly" do
      context "on creation" do
        let!(:rdv) { build(:rdv, organisation: organisation) }

        it "does not send webhook" do
          rdv.skip_webhooks = true
          expect do
            rdv.save
          end.not_to have_enqueued_job
        end
      end

      it "does not send webhook on update" do
        expect do
          rdv.update(status: :excused, skip_webhooks: true)
        end.not_to have_enqueued_job
      end

      it "does not send webhook on deletion" do
        rdv.skip_webhooks = true
        expect do
          rdv.destroy
        end.not_to have_enqueued_job
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
          expect do
            rdv.save
          end.not_to have_enqueued_job
        end
      end

      it "does not notify on update" do
        expect do
          rdv.update(status: :excused)
        end.not_to have_enqueued_job
      end

      it "does not notify on deletion" do
        expect do
          rdv.destroy
        end.not_to have_enqueued_job
      end
    end
  end
end
