RSpec.describe Participation::StatusChangeable, type: :concern do
  before { stub_netsize_ok }

  describe "Participation change status" do
    let(:agent) { create :agent }
    let(:rdv) { create :rdv, :collectif, starts_at: Time.zone.tomorrow, agents: [agent] }
    let!(:organisation) { create(:organisation, rdvs: [rdv]) }
    let!(:webhook_endpoint) { create(:webhook_endpoint, organisation: organisation, subscriptions: ["rdv"]) }
    let(:participation1) { create(:participation, rdv: rdv) }
    let(:participation_with_excused_status) { create(:participation, rdv: rdv) }
    let(:participation_with_lifecycle_disabled) { create(:participation, rdv: rdv, send_lifecycle_notifications: false) }

    describe "when participation is revoked or excused" do
      Participation::CANCELLED_STATUSES.each do |status|
        it "send notifications and change participation object status to #{status}" do
          participation1.change_status_and_notify(agent, status)
          expect(participation1.reload.status).to eq(status)
          expect_notifications_sent_for(rdv, participation1.user, :rdv_cancelled)
        end
      end

      it "do not send notification when already excused or lifecycle off" do
        participation_with_excused_status.update!(status: "excused")
        participation_with_excused_status.change_status_and_notify(agent, "revoked")
        participation_with_lifecycle_disabled.change_status_and_notify(agent, "revoked")
        expect(participation_with_excused_status.reload.status).to eq("revoked")
        expect(participation_with_lifecycle_disabled.reload.status).to eq("revoked")
        expect_no_notifications
      end
    end

    describe "when participation is seen (no notifications)" do
      it "doesnt send notifications and change participation object status" do
        participation1.change_status_and_notify(agent, "seen")
        expect(participation1.reload.status).to eq("seen")
        expect_no_notifications_for_user(participation1.user)
      end
    end

    describe "when participation is noshow (no notifications)" do
      it "doesnt send notifications and change participation object status" do
        participation1.change_status_and_notify(agent, "noshow")
        expect(participation1.reload.status).to eq("noshow")
        expect_no_notifications_for_user(participation1.user)
      end
    end

    describe "when participation is reloaded from cancelled (excused or revoked)" do
      it "send notifications creation and change participation object status" do
        participation1.update(status: "excused")
        participation1.change_status_and_notify(agent, "unknown")
        expect(participation1.reload.status).to eq("unknown")
        expect_notifications_sent_for(rdv, participation1.user, :rdv_created)
      end

      it "do not send notification creation when lifecycle off and change participation object status" do
        participation_with_lifecycle_disabled.change_status_and_notify(agent, "excused")
        participation_with_lifecycle_disabled.change_status_and_notify(agent, "unknown")
        expect(participation_with_lifecycle_disabled.reload.status).to eq("unknown")
        expect_no_notifications_for_user(participation1.user)
      end
    end

    describe "triggers webhook" do
      it "sends a webhook" do
        rdv.reload
        expect(WebhookJob).to receive(:perform_later).at_least(1)
        participation1.change_status_and_notify(agent, "noshow")
      end
    end
  end
end
