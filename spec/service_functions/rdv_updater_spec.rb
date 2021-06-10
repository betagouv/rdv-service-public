# frozen_string_literal: true

describe RdvUpdater, type: :service do
  describe "#update" do
    it "true when everything is ok" do
      agent = build :agent
      rdv = create(:rdv, agents: [agent])
      rdv_params = {}
      expect(described_class.update(agent, rdv, rdv_params)).to eq(true)
    end

    it "call rdv.update with params" do
      agent = build :agent
      rdv = create(:rdv, context: "un contexte", agents: [agent])
      rdv_params = { context: "un autre context" }
      expect(rdv).to receive(:update).with(rdv_params)
      described_class.update(agent, rdv, rdv_params)
    end

    it "destroy all file_attentes" do
      agent = build :agent
      rdv = create(:rdv, agents: [agent])
      create(:file_attente, rdv: rdv)
      rdv_params = { status: "excused" }
      described_class.update(agent, rdv, rdv_params)
      expect(rdv.reload.file_attentes).to be_empty
    end

    it "return false when update fail" do
      agent = build :agent
      rdv = create(:rdv, agents: [agent])
      rdv_params = { agents: [] }
      expect(described_class.update(agent, rdv, rdv_params)).to eq(false)
    end

    it "notify user when rdv cancelled by agent" do
      agent = build :agent
      rdv = create(:rdv, agents: [agent], status: "waiting")
      rdv_params = { status: "excused" }
      expect(Notifications::Rdv::RdvCancelledService).to receive(:perform_with).with(rdv, agent)
      described_class.update(agent, rdv, rdv_params)
    end

    it "notify user and agent when rdv cancelled by user" do
      user = build(:user)
      rdv = create(:rdv, status: "waiting", users: [user])
      rdv_params = { status: "excused" }
      expect(Notifications::Rdv::RdvCancelledService).to receive(:perform_with).with(rdv, user)
      described_class.update(user, rdv, rdv_params)
    end

    it "force updated_at to ensure new version will be recorded" do
      now = Time.zone.local(2020, 4, 23, 12, 56)
      travel_to(now)
      previous_date = now - 3.days

      agent = build :agent
      rdv = create(:rdv, agents: [agent], updated_at: previous_date, context: "")
      rdv_params = { context: "un nouveau context" }
      described_class.update(agent, rdv, rdv_params)
      expect(rdv.reload.updated_at).to be_within(3.seconds).of now
      travel_back
    end

    it "reset cancelled_at when status change" do
      cancelled_at = Time.zone.local(2020, 1, 12, 12, 56)
      agent = build :agent
      rdv = create(:rdv, agents: [agent], status: "notexcused", cancelled_at: cancelled_at)
      rdv_params = { status: "waiting" }
      described_class.update(agent, rdv, rdv_params)
      expect(rdv.reload.cancelled_at).to eq(nil)
    end

    it "dont reset cancelled_at when no status change" do
      cancelled_at = Time.zone.local(2020, 1, 12, 12, 56)
      agent = build :agent
      rdv = create(:rdv, agents: [agent], status: "excused", cancelled_at: cancelled_at, context: "")
      rdv_params = { context: "something new" }
      described_class.update(agent, rdv, rdv_params)
      expect(rdv.reload.cancelled_at).to be_within(3.seconds).of cancelled_at
    end

    it "where status change from excused to notexcused, cancelled_at should be refresh" do
      now = Time.zone.local(2020, 4, 23, 12, 56)
      travel_to(now)
      agent = build :agent
      rdv = create(:rdv, agents: [agent], status: "excused", cancelled_at: Time.zone.parse("12/1/2020 12:56"))
      described_class.update(agent, rdv, { status: "notexcused" })
      expect(rdv.reload.cancelled_at).to be_within(3.seconds).of now
    end
  end
end
