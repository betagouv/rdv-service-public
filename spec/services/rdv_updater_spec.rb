describe RdvUpdater, type: :service do

  describe "#update" do
    it "true when everything is ok" do
      rdv_updater = RdvUpdater.new
      expect(rdv_updater.update).to eq(true)
    end
  end

end
