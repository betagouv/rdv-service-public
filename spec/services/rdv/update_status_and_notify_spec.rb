RSpec.describe Rdv::UpdateStatusAndNotify do
  subject(:perform) { described_class.new(rdv, agent, status: new_status).perform }

  let(:rdv) { create(:rdv, status: previous_status) }
  let(:agent) { rdv.agents.first }
  let(:previous_status) { :unknown }

  %w[excused revoked noshow].each do |status|
    context "when the status changed to #{status}" do
      let(:new_status) { status }

      it "updates the cancelled_at attribute" do
        expect { perform }.to change { rdv.reload.cancelled_at }.from(nil)
      end
    end
  end

  %w[unknown seen].each do |status|
    context "when the status changed to #{status}" do
      let(:new_status) { status }

      before { rdv.update!(cancelled_at: 1.day.ago, status: "noshow") }

      it "sets the cancelled_at attribute to nil" do
        expect { perform }.to change { rdv.reload.cancelled_at }.to(nil)
      end
    end
  end

  describe "clear the file_attentes" do
    let(:new_status) { :excused }

    it "destroy all file_attentes" do
      create(:file_attente, rdv: rdv)
      expect { perform }.to change { rdv.reload.file_attentes }.to([])
    end
  end

  describe "sends relevant notifications" do
    it "notifies agent when rdv is cancelled (excused)" do
      rdv.update_and_notify(agent, status: "excused")
      expect_notifications_sent_for(rdv, user, :rdv_cancelled)
      expect_notifications_sent_for(rdv, agent, :rdv_cancelled)
    end

    it "notifies agent and users when rdv is cancelled (revoked) for collective rdv" do
      rdv_co.update_and_notify(agent, status: "revoked")
      expect_notifications_sent_for(rdv_co, user_co1, :rdv_cancelled)
      expect_notifications_sent_for(rdv_co, user_co2, :rdv_cancelled)
      expect_notifications_sent_for(rdv_co, agent, :rdv_cancelled)
    end

    it "doesnt notify already cancelled participations" do
      rdv_co.participations.where(user: user_co1).first.update!(status: "excused")
      rdv_co.participations.reload
      rdv_co.update_and_notify(agent, status: "revoked")
      expect_no_notifications_for_user(user_co1)
      expect_notifications_sent_for(rdv_co, user_co2, :rdv_cancelled)
      expect_notifications_sent_for(rdv_co, agent, :rdv_cancelled)
    end

    context "when the status doesn't change" do
      it "does not notify when status does not change" do
        rdv.reload
        rdv.update!(status: "unknown")
        rdv.update_and_notify(agent, status: "unknown")
        expect_no_notifications
      end
    end

    it "call Notifiers::RdvCreated when reloaded status from cancelled status" do
      rdv.update!(status: "excused", cancelled_at: Time.zone.parse("12/1/2020 12:56"))
      rdv.update_and_notify(agent, status: "unknown")
      expect_notifications_sent_for(rdv, user, :rdv_created)
      expect_notifications_sent_for(rdv, agent, :rdv_created)
    end

    it "call Notifiers::RdvCreated when reloaded status from cancelled status for collective rdv" do
      rdv_co.update!(status: "revoked", cancelled_at: Time.zone.parse("12/1/2020 12:56"))
      rdv_co.update_and_notify(agent, status: "unknown")
      expect_notifications_sent_for(rdv_co, user_co1, :rdv_created)
      expect_notifications_sent_for(rdv_co, user_co2, :rdv_created)
      expect_notifications_sent_for(rdv_co, agent, :rdv_created)
    end
  end

  describe "#rdv_status_reloaded_from_cancelled?" do
    Rdv::CANCELLED_STATUSES.each do |cancelled_status|
      it "true when rdv status from #{cancelled_status} to unknown" do
        rdv.update!(status: cancelled_status)
        rdv.update!(status: "unknown")
        expect(rdv.rdv_status_reloaded_from_cancelled?).to be(true)
      end
    end

    Rdv::NOT_CANCELLED_STATUSES.each do |not_cancelled_status|
      # From unknown to unkown permet de tester le cas où il n'y a pas de changement sur le status
      it "false when rdv status from #{not_cancelled_status} to unknown" do
        rdv.update!(status: not_cancelled_status)
        rdv.update!(status: "unknown")
        expect(rdv.rdv_status_reloaded_from_cancelled?).to be(false)
      end
    end
  end

  describe "#change_participation_statuses on RDV.status change for collective rdv" do
    let(:rdv_co) { create(:rdv, :collectif, agents: [agent]) }
    let!(:participation1) { create(:participation, rdv: rdv_co) }
    let!(:participation2) { create(:participation, rdv: rdv_co) }
    let!(:participation_excused) { create(:participation, rdv: rdv_co, status: "excused") }
    let!(:participation_noshow) { create(:participation, rdv: rdv_co, status: "noshow") }

    context "when the status changed and is now seen" do
      it "updates participations statuses" do
        rdv_co.update_and_notify(agent, status: "seen")
        rdv_co.reload
        expect(participation1.reload.status).to eq("seen")
        expect(participation2.reload.status).to eq("seen")
        expect(participation_excused.reload.status).to eq("excused")
        expect(participation_noshow.reload.status).to eq("noshow")
      end
    end

    context "when the status changed and is now revoked" do
      it "updates participations statuses" do
        rdv_co.update_and_notify(agent, status: "revoked")
        rdv_co.reload
        expect(participation1.reload.status).to eq("revoked")
        expect(participation2.reload.status).to eq("revoked")
        expect(participation_excused.reload.status).to eq("excused")
      end
    end

    context "when the status changed and is now unknown (reset)" do
      it "updates (reset to unknown) all participations statuses" do
        rdv_co.update!(status: "revoked")
        rdv_co.update_and_notify(agent, status: "unknown")
        expect(rdv_co.participations.reload.map(&:status)).to all(include("unknown"))
      end
    end

    context "when the status changed and is now noshow" do
      it "doesnt update rdv and participations statuses" do
        rdv_co.update_and_notify(agent, status: "noshow")
        expect(rdv_co).not_to be_valid
        expect(rdv_co.reload.status).to eq("unknown")
        expect(participation1.reload.status).to eq("unknown")
        expect(participation2.reload.status).to eq("unknown")
      end
    end

    context "when the status changed and is now excused" do
      it "doesnt update rdv and participations statuses" do
        rdv_co.update_and_notify(agent, status: "excused")
        expect(rdv_co).not_to be_valid
        expect(rdv_co.reload.status).to eq("unknown")
        expect(participation1.reload.status).to eq("unknown")
        expect(participation2.reload.status).to eq("unknown")
      end
    end
  end

  describe "#change_participation_statuses on RDV.status change (individual rdvs)" do
    let(:rdv) { create(:rdv, agents: [agent]) }
    let!(:participation1) { create(:participation, rdv: rdv) }
    let!(:participation2) { create(:participation, rdv: rdv) }
    let!(:participation_excused) { create(:participation, rdv: rdv) }
    let!(:participation_noshow) { create(:participation, rdv: rdv) }

    before do
      participation_excused.update!(status: "excused")
      participation_noshow.update!(status: "noshow")
    end

    context "when the status changed and is now seen" do
      it "updates statuses" do
        rdv.update_and_notify(agent, status: "seen")
        rdv.reload
        expect(rdv.status).to eq("seen")
        expect(participation1.reload.status).to eq("seen")
        expect(participation2.reload.status).to eq("seen")
      end
    end

    context "when the status changed and is now revoked" do
      it "updates statuses" do
        rdv.update_and_notify(agent, status: "revoked")
        rdv.reload
        expect(rdv.status).to eq("revoked")
        expect(participation1.reload.status).to eq("revoked")
        expect(participation2.reload.status).to eq("revoked")
      end
    end

    context "when the status changed and is now noshow" do
      it "updates statuses" do
        rdv.update_and_notify(agent, status: "noshow")
        rdv.reload
        expect(rdv.status).to eq("noshow")
        expect(participation1.reload.status).to eq("noshow")
        expect(participation2.reload.status).to eq("noshow")
      end
    end

    context "when the status changed and is now excused" do
      it "updates statuses" do
        rdv.update_and_notify(agent, status: "excused")
        rdv.reload
        expect(rdv.status).to eq("excused")
        expect(participation1.reload.status).to eq("excused")
        expect(participation2.reload.status).to eq("excused")
      end
    end

    context "when the status changed and is now unknown (reset)" do
      it "updates (reset to unknown) all participations statuses" do
        rdv.update!(status: "revoked")
        rdv.update_and_notify(agent, status: "unknown")
        expect(rdv.participations.reload.map(&:status)).to all(include("unknown"))
      end
    end
  end
end
