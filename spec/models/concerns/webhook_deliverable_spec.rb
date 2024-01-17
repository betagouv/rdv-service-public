describe WebhookDeliverable, type: :concern do
  include ActiveJob::TestHelper

  let!(:organisation) { create(:organisation) }
  let!(:webhook_endpoint) do
    create(
      :webhook_endpoint,
      organisation: organisation,
      subscriptions: %w[rdv absence plage_ouverture agent agent_role user user_profile]
    )
  end
  let!(:rdv) { create(:rdv, organisation: organisation) }
  let!(:agent_admin) { create(:agent, admin_role_in_organisations: [organisation]) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let!(:user) { create(:user, organisations: [organisation]) }

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

      it "notifies on agent_role deletion" do
        expect do
          service = AgentRemoval.new(agent.reload, organisation)
          expect(service).to be_valid
          service.remove!
        end.to have_enqueued_job(WebhookJob).with(json_payload_with_meta("event", "destroyed"), webhook_endpoint.id)
          .and have_enqueued_job(WebhookJob).with(json_payload_with_meta("model", "AgentRole"), webhook_endpoint.id)
      end

      it "Agent removal service does not send webhook for agent model" do
        # We soft delete agents when they are removed from the last organisation but actually there is NO webhook sent for agent model deletion
        expect do
          service = AgentRemoval.new(agent.reload, organisation)
          expect(service).to be_valid
          service.remove!
        end.not_to have_enqueued_job(WebhookJob).with(json_payload_with_meta("model", "Agent"), webhook_endpoint.id)
      end

      it "notifies on user_profile deletion" do
        expect do
          user.soft_delete(organisation)
        end.to have_enqueued_job(WebhookJob).with(json_payload_with_meta("event", "destroyed"), webhook_endpoint.id)
          .and have_enqueued_job(WebhookJob).with(json_payload_with_meta("model", "UserProfile"), webhook_endpoint.id)
      end

      it "User soft delete does not send webhook for user model" do
        # We anonymize users when they are removed from the last organisation but actually there is NO webhook sent for user model deletion
        expect do
          user.soft_delete(organisation)
          expect(user.first_name).to eq("Usager supprimé")
        end.not_to have_enqueued_job(WebhookJob).with(json_payload_with_meta("model", "User"), webhook_endpoint.id)
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
