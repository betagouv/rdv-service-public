describe RdvUpdater, type: :service do

  describe "#update" do
    it "true when everything is ok" do
      rdv = create(:rdv)
      rdv_updater = RdvUpdater.new(rdv)
      rdv_params = {}
      expect(rdv_updater.update(rdv_params)).to eq(true)
    end

    it "call rdv.update with params" do
      rdv = create(:rdv, context: "un contexte")
      rdv_updater = RdvUpdater.new(rdv)
      rdv_params = {context: "un autre context"}

      expect(rdv).to receive(:update).with(rdv_params).and_return(true)
      rdv_updater.update(rdv_params)
    end

    it "return false when update fail" do
      rdv = create(:rdv, agents: [create(:agent)])
      rdv_updater = RdvUpdater.new(rdv)
      rdv_params = attributes_for(:rdv, :future, agents: [])
      expect(rdv_updater.update(rdv_params)).to eq(false)
    end

    it "notify user when rdv cancelled" do
      rdv = create(:rdv, status: "waiting")
      rdv_updater = RdvUpdater.new(rdv)
      rdv_params = {status: "excused"}

      expect(Notifications::Rdv::RdvCancelledByAgentService).to receive(:perform_with).with(rdv).and_return(true)

      rdv_updater.update(rdv_params)
    end
  end

end
