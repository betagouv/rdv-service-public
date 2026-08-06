RSpec.describe Rdv::UpdateStatusAndNotify do
  subject(:perform) { described_class.new(rdv, agent, status: new_status).perform }

  before { stub_netsize_ok }

  let(:rdv) { create(:rdv, status: previous_status) }
  let(:agent) { rdv.agents.first }
  let(:user) { rdv.users.first }
  let(:organisation) { create(:organisation) }
  let(:previous_status) { :unknown }

  %w[excused revoked noshow].each do |status|
    context "when the status changed to #{status}" do
      let(:new_status) { status }

      it "updates the cancelled_at attribute" do
        expect { perform }.to change { rdv.reload.cancelled_at }.from(nil)
      end
    end
  end

  context "when the status changed to seen" do
    let(:new_status) { "seen" }

    before { rdv.update!(cancelled_at: 1.day.ago, status: "noshow") }

    it "sets the cancelled_at attribute to nil" do
      expect { perform }.to change { rdv.reload.cancelled_at }.to(nil)
    end
  end

  context "when resetting the status to unknown" do
    subject(:perform) { described_class.new(rdv, agent, status: "unknown").perform }

    context "when the rdv was a noshow" do
      let(:rdv) { create(:rdv, status: "noshow", cancelled_at: 1.day.ago) }

      it "doesn't notify and sets the cancelled_at attribute to nil" do
        expect { perform }.to change { rdv.reload.cancelled_at }.to(nil)
        expect_no_notifications
      end
    end

    context "when it was already in that state" do
      let(:rdv) { create(:rdv, status: :unknown) }

      it "does not notify" do
        perform
        expect_no_notifications
      end
    end

    Rdv::CANCELLED_STATUSES.each do |cancelled_status|
      it "sends a notification when the previous state was #{cancelled_status}" do
        rdv.update!(status: cancelled_status)
        perform

        expect_notifications_sent_for(rdv, user, :rdv_created)
        expect_notifications_sent_for(rdv, agent, :rdv_created)
      end
    end

    it "doesn't notify when rdv status changes from seen to unknown" do
      rdv.update!(status: "seen")
      perform
      expect_no_notifications
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
    let(:rdv_co) { create(:rdv, motif:, users: [user_co1, user_co2], agents: [agent], organisation:) }
    let(:motif) { create(:motif, :collectif, organisation:) }
    let(:user_co1) { create(:user) }
    let(:user_co2) { create(:user) }

    it "notifies agent when rdv is cancelled (excused)" do
      described_class.new(rdv, agent, status: "excused").perform
      expect_notifications_sent_for(rdv, user, :rdv_cancelled)
      expect_notifications_sent_for(rdv, agent, :rdv_cancelled)
    end

    it "notifies agent and users when rdv is cancelled (revoked) for collective rdv" do
      described_class.new(rdv_co, agent, status: "revoked").perform
      expect_notifications_sent_for(rdv_co, user_co1, :rdv_cancelled)
      expect_notifications_sent_for(rdv_co, user_co2, :rdv_cancelled)
      expect_notifications_sent_for(rdv_co, agent, :rdv_cancelled)
    end

    it "doesnt notify already cancelled participations" do
      rdv_co.participations.where(user: user_co1).first.update!(status: "excused")
      rdv_co.participations.reload
      described_class.new(rdv_co, agent, status: "revoked").perform
      expect_no_notifications_for_user(user_co1)
      expect_notifications_sent_for(rdv_co, user_co2, :rdv_cancelled)
      expect_notifications_sent_for(rdv_co, agent, :rdv_cancelled)
    end

    it "call Notifiers::RdvCreated when reloaded status from cancelled status for collective rdv" do
      rdv_co.update!(status: "revoked", cancelled_at: Time.zone.parse("12/1/2020 12:56"))
      described_class.new(rdv_co, agent, status: "unknown").perform
      expect_notifications_sent_for(rdv_co, user_co1, :rdv_created)
      expect_notifications_sent_for(rdv_co, user_co2, :rdv_created)
      expect_notifications_sent_for(rdv_co, agent, :rdv_created)
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
        described_class.new(rdv_co, agent, status: "seen").perform
        rdv_co.reload
        expect(participation1.reload.status).to eq("seen")
        expect(participation2.reload.status).to eq("seen")
        expect(participation_excused.reload.status).to eq("excused")
        expect(participation_noshow.reload.status).to eq("noshow")
      end
    end

    context "when the status changed and is now revoked" do
      it "updates participations statuses" do
        described_class.new(rdv_co, agent, status: "revoked").perform
        rdv_co.reload
        expect(participation1.reload.status).to eq("revoked")
        expect(participation2.reload.status).to eq("revoked")
        expect(participation_excused.reload.status).to eq("excused")
      end
    end

    context "when the status changed and is now unknown (reset)" do
      it "updates (reset to unknown) all participations statuses" do
        rdv_co.update!(status: "revoked")
        described_class.new(rdv_co, agent, status: "unknown").perform
        expect(rdv_co.participations.reload.map(&:status)).to all(include("unknown"))
      end
    end

    context "when the status changed and is now noshow" do
      it "doesnt update rdv and participations statuses" do
        described_class.new(rdv_co, agent, status: "noshow").perform
        expect(rdv_co).not_to be_valid
        expect(rdv_co.reload.status).to eq("unknown")
        expect(participation1.reload.status).to eq("unknown")
        expect(participation2.reload.status).to eq("unknown")
      end
    end

    context "when the status changed and is now excused" do
      it "doesnt update rdv and participations statuses" do
        described_class.new(rdv_co, agent, status: "excused").perform
        expect(rdv_co).not_to be_valid
        expect(rdv_co.reload.status).to eq("unknown")
        expect(participation1.reload.status).to eq("unknown")
        expect(participation2.reload.status).to eq("unknown")
      end
    end
  end

  describe "#change_participation_statuses on RDV.status change (individual rdvs)" do
    let(:agent) { create(:agent, rdv_notifications_level: "all") }
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
        described_class.new(rdv, agent, status: "seen").perform
        rdv.reload
        expect(rdv.status).to eq("seen")
        expect(participation1.reload.status).to eq("seen")
        expect(participation2.reload.status).to eq("seen")
      end
    end

    context "when the status changed and is now revoked" do
      it "updates statuses" do
        described_class.new(rdv, agent, status: "revoked").perform
        rdv.reload
        expect(rdv.status).to eq("revoked")
        expect(participation1.reload.status).to eq("revoked")
        expect(participation2.reload.status).to eq("revoked")
      end
    end

    context "when the status changed and is now noshow" do
      it "updates statuses" do
        described_class.new(rdv, agent, status: "noshow").perform

        expect(rdv.reload.status).to eq("noshow")
        expect(participation1.reload.status).to eq("noshow")
        expect(participation2.reload.status).to eq("noshow")
      end
    end

    context "when the status changed and is now excused" do
      it "updates statuses" do
        described_class.new(rdv, agent, status: "excused").perform

        expect(rdv.reload.status).to eq("excused")
        expect(participation1.reload.status).to eq("excused")
        expect(participation2.reload.status).to eq("excused")
      end
    end

    context "when the status changed and is now unknown (reset)" do
      it "updates (reset to unknown) all participations statuses" do
        rdv.update!(status: "revoked")

        described_class.new(rdv, agent, status: "unknown").perform
        expect(rdv.participations.reload.map(&:status)).to all(include("unknown"))
      end
    end
  end
end
