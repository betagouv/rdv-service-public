describe AgentsHelper do
  describe "#build_link_to_rdv_wizard_params" do
    it "step 2 par défaut" do
      user_ids = []
      creneau = Creneau.new
      lieu = create(:lieu)
      creneau.lieu_id = lieu.id
      motif = create(:motif)
      creneau.motif = motif
      expect(build_link_to_rdv_wizard_params(creneau, user_ids)[:step]).to eq(2)
    end

    it "durée du motif par défaut" do
      user_ids = []
      creneau = Creneau.new
      creneau.lieu_id = create(:lieu).id
      motif = create(:motif)
      creneau.motif = motif
      expect(build_link_to_rdv_wizard_params(creneau, user_ids)[:duration_in_min]).to eq(motif.default_duration_in_min)
    end

    it "liste des usagers" do
      user_ids = []
      creneau = Creneau.new
      creneau.lieu_id = create(:lieu).id
      motif = create(:motif)
      creneau.motif = motif
      expect(build_link_to_rdv_wizard_params(creneau, user_ids)[:user_ids]).to eq(nil)
    end

    it "liste des usagers" do
      user = create(:user)
      user_ids = [user.id.to_s]
      creneau = Creneau.new
      creneau.lieu_id = create(:lieu).id
      motif = create(:motif)
      creneau.motif = motif
      expect(build_link_to_rdv_wizard_params(creneau, user_ids)["user_ids[]"]).to eq(user.id)
    end
  end
end
