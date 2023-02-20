# frozen_string_literal: true

RSpec.describe RdvsUser::StatusChangeable, type: :concern do
  before { stub_netsize_ok }

  describe "RdvsUser change status" do
    let(:agent) { create :agent }
    let(:rdv) { create :rdv, :collectif, starts_at: Time.zone.tomorrow, agents: [agent] }
    let!(:organisation) { create(:organisation, rdvs: [rdv]) }
    let!(:webhook_endpoint) { create(:webhook_endpoint, organisation: organisation, subscriptions: ["rdv"]) }
    let(:rdv_user1) { create(:rdvs_user, rdv: rdv) }
    let(:rdv_user_with_excused_status) { create(:rdvs_user, rdv: rdv) }
    let(:rdv_user_with_lifecycle_disabled) { create(:rdvs_user, rdv: rdv, send_lifecycle_notifications: false) }

    describe "when rdv_user is revoked or excused" do
      RdvsUser::CANCELLED_STATUSES.each do |status|
        it "send notifications and change rdv_user object status to #{status}" do
          rdv_user1.change_status_and_notify(agent, status)
          expect(rdv_user1.reload.status).to eq(status)
          expect_notifications_sent_for(rdv, rdv_user1.user, :rdv_cancelled)
        end
      end

      it "do not send notification when already excused or lifecycle off" do
        rdv_user_with_excused_status.update!(status: "excused")
        rdv_user_with_excused_status.change_status_and_notify(agent, "revoked")
        rdv_user_with_lifecycle_disabled.change_status_and_notify(agent, "revoked")
        expect(rdv_user_with_excused_status.reload.status).to eq("revoked")
        expect(rdv_user_with_lifecycle_disabled.reload.status).to eq("revoked")
        expect_no_notifications
      end
    end

    describe "when rdv_user is seen (no notifications)" do
      it "doesnt send notifications and change rdv_user object status" do
        rdv_user1.change_status_and_notify(agent, "seen")
        expect(rdv_user1.reload.status).to eq("seen")
        expect_no_notifications_for_user(rdv_user1.user)
      end
    end

    describe "when rdv_user is noshow (no notifications)" do
      it "doesnt send notifications and change rdv_user object status" do
        rdv_user1.change_status_and_notify(agent, "noshow")
        expect(rdv_user1.reload.status).to eq("noshow")
        expect_no_notifications_for_user(rdv_user1.user)
      end
    end

    describe "when rdv_user is reloaded from cancelled (excused or revoked)" do
      it "send notifications creation and change rdv_user object status" do
        rdv_user1.update(status: "excused")
        rdv_user1.change_status_and_notify(agent, "unknown")
        expect(rdv_user1.reload.status).to eq("unknown")
        expect_notifications_sent_for(rdv, rdv_user1.user, :rdv_created)
      end

      it "do not send notification creation when lifecycle off and change rdv_user object status" do
        rdv_user_with_lifecycle_disabled.change_status_and_notify(agent, "excused")
        rdv_user_with_lifecycle_disabled.change_status_and_notify(agent, "unknown")
        expect(rdv_user_with_lifecycle_disabled.reload.status).to eq("unknown")
        expect_no_notifications_for_user(rdv_user1.user)
      end
    end

    describe "triggers webhook" do
      it "sends a webhook" do
        rdv.reload
        expect(WebhookJob).to receive(:perform_later).at_least(1)
        rdv_user1.change_status_and_notify(agent, "noshow")
      end
    end
  end
end
