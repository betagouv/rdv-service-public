describe RdvUpdater, type: :service do

  describe "#update" do
    it "true when everything is ok" do
      rdv = create(:rdv, context: "un contexte")
      rdv_updater = RdvUpdater.new(rdv)
      rdv_params = {context: "un autre context"}
      expect(rdv_updater.update(rdv_params)).to eq(true)
      expect(rdv.reload.context).to eq("un autre context")
    end
  end

end
