describe RdvUpdater, type: :service do
  describe "#update" do
    it "true when everything is ok" do
      rdv = create(:rdv)
      rdv_params = {}
      expect(RdvUpdater.update(rdv, rdv_params)).to eq("Le rendez-vous a été modifié.")
    end

    it "call rdv.update with params" do
      rdv = create(:rdv, context: "un contexte")
      rdv_params = { context: "un autre context" }
      expect(rdv).to receive(:update).with(rdv_params)
      RdvUpdater.update(rdv, rdv_params)
    end

    it "return false when update fail" do
      rdv = create(:rdv, agents: [create(:agent)])
      rdv_params = { agents: []}
      expect(RdvUpdater.update(rdv, rdv_params)).to eq(false)
    end

    it "notify user when rdv cancelled" do
      rdv = create(:rdv, status: "waiting")
      rdv_params = { status: "excused" }
      expect(Notifications::Rdv::RdvCancelledByAgentService).to receive(:perform_with).with(rdv)
      RdvUpdater.update(rdv, rdv_params)
    end

    it "force updated_at to ensure new version will be recorded" do
      now = Time.new(2020, 4, 23, 12, 56)
      travel_to(now)
      previous_date = now - 3.days

      rdv = create(:rdv, updated_at: previous_date, context: "")
      rdv_params = { context: "un nouveau context" }
      RdvUpdater.update(rdv, rdv_params)
      expect(rdv.reload.updated_at).to be_within(3.second).of now
      travel_back
    end

    it "reset cancelled_at when status change" do
      cancelled_at = Time.new(2020, 1, 12, 12, 56)
      rdv = create(:rdv, status: "notexcused", cancelled_at: cancelled_at)
      rdv_params = { status: "waiting" }
      RdvUpdater.update(rdv, rdv_params)
      expect(rdv.reload.cancelled_at).to eq(nil)
    end

    it "dont reset cancelled_at when no status change" do
      cancelled_at = Time.new(2020, 1, 12, 12, 56)
      rdv = create(:rdv, status: "excused", cancelled_at: cancelled_at, context: "")
      rdv_params = { context: "something new" }
      RdvUpdater.update(rdv, rdv_params)
      expect(rdv.reload.cancelled_at).to be_within(3.second).of cancelled_at
    end

    it "where status change from excused to notexcused, cancelled_at should be refresh" do
      now = Time.new(2020, 4, 23, 12, 56)
      travel_to(now)
      rdv = create(:rdv, status: "excused", cancelled_at: Time.zone.parse("12/1/2020 12:56"))
      RdvUpdater.update(rdv, { status: "notexcused" })
      expect(rdv.reload.cancelled_at).to be_within(3.second).of now
    end
  end
end
