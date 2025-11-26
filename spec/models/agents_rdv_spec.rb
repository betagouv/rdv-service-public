RSpec.describe AgentsRdv do
  describe "données dénormalisées depuis le rendez-vous pour l'index du Calculator" do
    it "copie les données quand on ajoute un agent au rendez-vous" do
      rdv = create(:rdv)
      agent = create(:agent)
      agent_rdv = described_class.create(rdv:, agent:)
      expect(agent_rdv.reload).to have_attributes(
        {
          readonly_rdv_starts_at: rdv.starts_at,
          readonly_rdv_ends_at: rdv.ends_at,
          readonly_busy_in_the_future: true,
        }
      )
    end
  end
end
