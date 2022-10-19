# frozen_string_literal: true

RSpec.describe RdvsUser::StatusChangeable, type: :concern do
  describe "RdvsUser change status" do
    let(:agent) { create :agent }
    let(:rdv) { create :rdv, :collectif, starts_at: Time.zone.tomorrow, agents: [agent] }
    let(:rdv_user1) { create(:rdvs_user, rdv: rdv) }
    let(:rdv_user_with_excused_status) { create(:rdvs_user, rdv: rdv) }
    let(:rdv_user_with_lifecycle_disabled) { create(:rdvs_user, rdv: rdv, send_lifecycle_notifications: false) }

    describe "when rdv_user is revoked or excused" do
      %w[excused revoked].each do |status|
        it "send notifications and change rdv_user object status to #{status}" do
          expect(Notifiers::RdvCancelled).to receive(:perform_with).with(rdv, agent, [rdv_user1.user])
          rdv_user1.change_status(agent, status)
          expect(rdv_user1.reload.status).to eq(status)
        end
      end

      it "do not send notification when already excused or lifecycle off" do
        rdv_user_with_excused_status.update!(status: "excused")
        expect(Notifiers::RdvCancelled).not_to receive(:perform_with).with(rdv, agent, [rdv_user_with_excused_status.user])
        expect(Notifiers::RdvCancelled).not_to receive(:perform_with).with(rdv, agent, [rdv_user_with_lifecycle_disabled.user])
        rdv_user_with_excused_status.change_status(agent, "revoked")
        rdv_user_with_lifecycle_disabled.change_status(agent, "revoked")
        expect(rdv_user_with_excused_status.reload.status).to eq("revoked")
        expect(rdv_user_with_lifecycle_disabled.reload.status).to eq("revoked")
      end
    end

    describe "when rdv_user is seen (no notifications)" do
      it "doesnt send notifications and change rdv_user object status" do
        expect(Notifiers::RdvCancelled).not_to receive(:perform_with).with(rdv, agent, [rdv_user1.user])
        expect(Notifiers::RdvCreated).not_to receive(:perform_with).with(rdv, agent, [rdv_user1.user])
        rdv_user1.change_status(agent, "seen")
        expect(rdv_user1.reload.status).to eq("seen")
      end
    end

    describe "when rdv_user is noshow (no notifications)" do
      it "doesnt send notifications and change rdv_user object status" do
        expect(Notifiers::RdvCancelled).not_to receive(:perform_with).with(rdv, agent, [rdv_user1.user])
        expect(Notifiers::RdvCreated).not_to receive(:perform_with).with(rdv, agent, [rdv_user1.user])
        rdv_user1.change_status(agent, "noshow")
        expect(rdv_user1.reload.status).to eq("noshow")
      end
    end

    describe "when rdv_user is reloaded from cancelled (excused or revoked)" do
      it "send notifications creation and change rdv_user object status" do
        expect(Notifiers::RdvCreated).to receive(:perform_with).with(rdv, agent, [rdv_user1.user])
        rdv_user1.change_status(agent, "excused")
        rdv_user1.change_status(agent, "unknown")
        expect(rdv_user1.reload.status).to eq("unknown")
      end

      it "do not send notification creation when lifecycle off and change rdv_user object status" do
        expect(Notifiers::RdvCreated).not_to receive(:perform_with).with(rdv, agent, [rdv_user_with_lifecycle_disabled.user])
        rdv_user_with_lifecycle_disabled.change_status(agent, "excused")
        rdv_user_with_lifecycle_disabled.change_status(agent, "unknown")
        expect(rdv_user_with_lifecycle_disabled.reload.status).to eq("unknown")
      end
    end
  end
end
