# frozen_string_literal: true

RSpec.describe RdvsUser::StatusChangeable, type: :concern do
  before { stub_netsize_ok }

  describe "RdvsUser change status" do
    let(:agent) { create :agent }
    let(:rdv) { create :rdv, :collectif, starts_at: Time.zone.tomorrow, agents: [agent] }
    let(:rdv_user1) { create(:rdvs_user, rdv: rdv) }
    let(:rdv_user_with_excused_status) { create(:rdvs_user, rdv: rdv) }
    let(:rdv_user_with_lifecycle_disabled) { create(:rdvs_user, rdv: rdv, send_lifecycle_notifications: false) }

    describe "when rdv_user is revoked or excused" do
      %w[excused revoked].each do |status|
        it "send notifications and change rdv_user object status to #{status}" do
          expect(Notifiers::RdvCancelled).to receive(:new).with(rdv, agent, [rdv_user1.user]).and_call_original
          rdv_user1.change_status_and_notify(agent, status)
          perform_enqueued_jobs
          expect(ActionMailer::Base.deliveries.map(&:to).flatten).to match_array([rdv_user1.user.email])
          expect(rdv_user1.reload.status).to eq(status)
        end
      end

      it "do not send notification when already excused or lifecycle off" do
        rdv_user_with_excused_status.update!(status: "excused")
        expect(Notifiers::RdvCancelled).not_to receive(:new).with(rdv, agent, [rdv_user_with_excused_status.user])
        expect(Notifiers::RdvCancelled).not_to receive(:new).with(rdv, agent, [rdv_user_with_lifecycle_disabled.user])
        rdv_user_with_excused_status.change_status_and_notify(agent, "revoked")
        rdv_user_with_lifecycle_disabled.change_status_and_notify(agent, "revoked")
        expect(rdv_user_with_excused_status.reload.status).to eq("revoked")
        expect(rdv_user_with_lifecycle_disabled.reload.status).to eq("revoked")
      end
    end

    describe "when rdv_user is seen (no notifications)" do
      it "doesnt send notifications and change rdv_user object status" do
        expect(Notifiers::RdvCancelled).not_to receive(:new).with(rdv, agent, [rdv_user1.user])
        expect(Notifiers::RdvCreated).not_to receive(:new).with(rdv, agent, [rdv_user1.user])
        rdv_user1.change_status_and_notify(agent, "seen")
        expect(rdv_user1.reload.status).to eq("seen")
      end
    end

    describe "when rdv_user is noshow (no notifications)" do
      it "doesnt send notifications and change rdv_user object status" do
        expect(Notifiers::RdvCancelled).not_to receive(:new).with(rdv, agent, [rdv_user1.user])
        expect(Notifiers::RdvCreated).not_to receive(:new).with(rdv, agent, [rdv_user1.user])
        rdv_user1.change_status_and_notify(agent, "noshow")
        expect(rdv_user1.reload.status).to eq("noshow")
      end
    end

    describe "when rdv_user is reloaded from cancelled (excused or revoked)" do
      it "send notifications creation and change rdv_user object status" do
        expect(Notifiers::RdvCreated).to receive(:new).with(rdv, agent, [rdv_user1.user])
        rdv_user1.change_status_and_notify(agent, "excused")
        rdv_user1.change_status_and_notify(agent, "unknown")
        perform_enqueued_jobs
        expect(ActionMailer::Base.deliveries.map(&:to).flatten).to match_array([rdv_user1.user.email])
        expect(rdv_user1.reload.status).to eq("unknown")
      end

      it "do not send notification creation when lifecycle off and change rdv_user object status" do
        expect(Notifiers::RdvCreated).not_to receive(:new).with(rdv, agent, [rdv_user_with_lifecycle_disabled.user])
        rdv_user_with_lifecycle_disabled.change_status_and_notify(agent, "excused")
        rdv_user_with_lifecycle_disabled.change_status_and_notify(agent, "unknown")
        expect(rdv_user_with_lifecycle_disabled.reload.status).to eq("unknown")
      end
    end
  end
end
