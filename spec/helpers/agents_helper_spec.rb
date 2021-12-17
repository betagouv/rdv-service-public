# frozen_string_literal: true

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

    describe "liste des usagers" do
      subject { build_link_to_rdv_wizard_params(creneau, form)["user_ids"] }

      let(:creneau) { build :creneau, lieu_id: create(:lieu).id }
      let(:form) { AgentCreneauxSearchForm.new(user_ids: [user_ids]) }

      context "when user is nil" do
        let(:user_ids) { "" }

        it { is_expected.to eq [""] }
      end

      context "when user is set" do
        let(:user) { create(:user) }
        let(:user_ids) { user.id.to_s }

        it { is_expected.to eq [user.id.to_s] }
      end
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
