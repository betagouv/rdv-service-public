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
      expect(build_link_to_rdv_wizard_params(creneau, user_ids)["user_ids"]).to eq(user_ids)
    end
  end

  describe "#display_meta_note" do
    it "render date and agent full_name" do
      service = build(:service, name: "CIA")
      agent = build(:agent, first_name: "John", last_name: "Francis", service: service)
      note = build(:user_note, created_at: Time.new(2020, 5, 23, 4, 56), agent: agent)
      expect(display_meta_note(note)).to include("le 23/05/2020", "John Francis (CIA)")
    end

    it "render only date when no agent (need for previous notes without agent)" do
      note = build(:user_note, created_at: Time.new(2020, 5, 23, 4, 56), agent: nil)
      expect(display_meta_note(note)).to include("le 23/05/2020")
    end
  end
end
