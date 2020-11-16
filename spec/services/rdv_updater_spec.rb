describe RdvUpdater, type: :service do

  describe "#update" do
    it "true when everything is ok" do
      rdv = create(:rdv, context: "un contexte")
      rdv_updater = RdvUpdater.new(rdv)
      rdv_params = {context: "un autre context"}
      expect(rdv_updater.update(rdv_params)).to eq(true)
      expect(rdv.reload.context).to eq("un autre context")
    end

    it "call rdv.update with params" do
      rdv = create(:rdv, context: "un contexte")
      rdv_updater = RdvUpdater.new(rdv)
      rdv_params = {context: "un autre context"}

      expect(rdv).to receive(:update).with(rdv_params).and_return(true)
      rdv_updater.update(rdv_params)
    end

  end

end
