describe RdvUpdater, type: :service do

  describe "#update" do
    it "true when everything is ok" do
      rdv = create(:rdv)
      rdv_updater = RdvUpdater.new(rdv)
      expect(rdv_updater.update).to eq(true)
    end
  end

end
