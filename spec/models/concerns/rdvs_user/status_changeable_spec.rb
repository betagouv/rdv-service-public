# frozen_string_literal: true

RSpec.describe RdvsUser::StatusChangeable, type: :concern do
  describe "RdvsUser change status" do
    let(:motif) { create :motif, :collectif }
    let(:agent) { create :agent }
    let(:rdv) { create :rdv, starts_at: Time.zone.tomorrow, motif: motif, agents: [agent] }
    let(:user1) { create :user }
    let(:rdv_user1) { create(:rdvs_user, user: user1, rdv: rdv) }
    let(:user_with_excused_status) { create :user }
    let(:rdv_user_with_excused_status) { create(:rdvs_user, user: user_with_excused_status, rdv: rdv) }
    let(:user_with_lifecycle_disabled) { create(:user) }
    let(:rdv_user_with_lifecycle_disabled) { create(:rdvs_user, user: user_with_lifecycle_disabled, rdv: rdv, send_lifecycle_notifications: false) }

    describe "when rdv_user is revoked or excused" do
      it do
        expect(Notifiers::RdvCancelled).to receive(:perform_with).with(rdv, agent, [user1])
        rdv_user1.change_status(agent, "revoked")
        expect(rdv_user1.reload.status).to eq("revoked")
      end

      it "do not send notification when already excused or lifecycle off" do
        rdv_user_with_excused_status.update!(status: "excused")
        expect(Notifiers::RdvCancelled).not_to receive(:perform_with).with(rdv, agent, [user_with_excused_status])
        expect(Notifiers::RdvCancelled).not_to receive(:perform_with).with(rdv, agent, [user_with_lifecycle_disabled])
        rdv_user_with_excused_status.change_status(agent, "revoked")
        rdv_user_with_lifecycle_disabled.change_status(agent, "revoked")
        expect(rdv_user_with_excused_status.reload.status).to eq("revoked")
        expect(rdv_user_with_lifecycle_disabled.reload.status).to eq("revoked")
      end
    end

    describe "when rdv_user is seen (no notifications)" do
      it do
        expect(Notifiers::RdvCancelled).not_to receive(:perform_with).with(rdv, agent, [user1])
        expect(Notifiers::RdvCreated).not_to receive(:perform_with).with(rdv, agent, [user1])
        rdv_user1.change_status(agent, "seen")
        expect(rdv_user1.reload.status).to eq("seen")
      end
    end

    describe "when rdv_user is noshow (no notifications)" do
      it do
        expect(Notifiers::RdvCancelled).not_to receive(:perform_with).with(rdv, agent, [user1])
        expect(Notifiers::RdvCreated).not_to receive(:perform_with).with(rdv, agent, [user1])
        rdv_user1.change_status(agent, "noshow")
        expect(rdv_user1.reload.status).to eq("noshow")
      end
    end

    describe "when rdv_user is reloaded from cancelled (excused or revoked)" do
      it do
        expect(Notifiers::RdvCancelled).to receive(:perform_with).with(rdv, agent, [user1])
        expect(Notifiers::RdvCreated).to receive(:perform_with).with(rdv, agent, [user1])
        rdv_user1.change_status(agent, "excused")
        rdv_user1.change_status(agent, "unknown")
        expect(rdv_user1.reload.status).to eq("unknown")
      end

      it "do not send notification when lifecycle off" do
        expect(Notifiers::RdvCancelled).not_to receive(:perform_with).with(rdv, agent, [user_with_lifecycle_disabled])
        expect(Notifiers::RdvCreated).not_to receive(:perform_with).with(rdv, agent, [user_with_lifecycle_disabled])
        rdv_user_with_lifecycle_disabled.change_status(agent, "excused")
        rdv_user_with_lifecycle_disabled.change_status(agent, "unknown")
        expect(rdv_user_with_lifecycle_disabled.reload.status).to eq("unknown")
      end
    end
  end
end
