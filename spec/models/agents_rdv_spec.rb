RSpec.describe AgentsRdv do
  describe "données dénormalisées depuis le rendez-vous pour l'index du Calculator" do
    it "copie les données à la création du rendez-vous" do
      rdv = build(:rdv)
      rdv.save!
      expect(rdv.agents_rdvs.first.reload).to have_attributes(
        {
          calculator_rdv_starts_at: rdv.starts_at,
          calculator_rdv_ends_at: rdv.ends_at,
          calculator_rdv_not_cancelled_and_in_the_future: true,
        }
      )
    end

    it "met à jour les données quand le rendez-vous est modifié" do
      rdv = create(:rdv, starts_at: 3.days.from_now)

      rdv.update!(starts_at: 3.days.ago)

      expect(rdv.agents_rdvs.first.reload).to have_attributes(
        {
          calculator_rdv_starts_at: rdv.starts_at,
          calculator_rdv_ends_at: rdv.ends_at,
          calculator_rdv_not_cancelled_and_in_the_future: false,
        }
      )
    end

    it "copie les données quand on ajoute un agent au rendez-vous" do
      rdv = create(:rdv)
      agent = create(:agent)
      agent_rdv = described_class.create(rdv:, agent:)
      expect(agent_rdv.reload).to have_attributes(
        {
          calculator_rdv_starts_at: rdv.starts_at,
          calculator_rdv_ends_at: rdv.ends_at,
          calculator_rdv_not_cancelled_and_in_the_future: true,
        }
      )
    end
  end
end
