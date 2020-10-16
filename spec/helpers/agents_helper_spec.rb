describe AgentsHelper do
  describe "#build_link_to_rdv_wizard_params" do
    it "step 2 par défaut" do
      creneau = Creneau.new
      lieu = create(:lieu)
      creneau.lieu_id = lieu.id
      motif = create(:motif)
      creneau.motif = motif
      form = AgentCreneauxSearchForm.new(user_ids: [])
      expect(build_link_to_rdv_wizard_params(creneau, form)[:step]).to eq(2)
    end

    it "durée du motif par défaut" do
      creneau = Creneau.new
      creneau.lieu_id = create(:lieu).id
      motif = create(:motif)
      creneau.motif = motif
      form = AgentCreneauxSearchForm.new(user_ids: [])
      expect(build_link_to_rdv_wizard_params(creneau, form)[:duration_in_min]).to eq(motif.default_duration_in_min)
    end

    it "liste des usagers" do
      creneau = Creneau.new
      creneau.lieu_id = create(:lieu).id
      motif = create(:motif)
      creneau.motif = motif
      form = AgentCreneauxSearchForm.new(user_ids: [])
      expect(build_link_to_rdv_wizard_params(creneau, form)[:user_ids]).to eq(nil)
    end

    it "liste des usagers" do
      user = create(:user)
      creneau = Creneau.new
      creneau.lieu_id = create(:lieu).id
      motif = create(:motif)
      creneau.motif = motif
      form = AgentCreneauxSearchForm.new(user_ids: [user.id.to_s])
      expect(build_link_to_rdv_wizard_params(creneau, form)["user_ids"]).to eq([user.id.to_s])
    end

    it "Contient le context" do
      creneau = Creneau.new
      creneau.lieu_id = create(:lieu).id
      motif = create(:motif)
      creneau.motif = motif
      form = AgentCreneauxSearchForm.new(context: "un super context")
      expect(build_link_to_rdv_wizard_params(creneau, form)["context"]).to eq("un super context")
    end
  end
end
