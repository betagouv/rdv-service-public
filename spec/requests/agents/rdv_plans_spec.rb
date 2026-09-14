RSpec.describe "Specs pour vérifier qu'il n'est pas possible de faire des injections de paramètres sur les routes de rdv_plans" do
  let(:rdv_plan) { create(:rdv_plan, planning_agent: agent) }
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let(:organisation) { create(:organisation) }

  before { sign_in agent }

  describe "update_motif" do
    let(:motif_from_other_organisation) { create(:motif) }

    it "ne permet pas de mettre le motif d'une autre organisation sur le rdv_plan" do
      patch update_motif_agents_rdv_plan_path(rdv_plan, rdv_plan: { motif_id: motif_from_other_organisation.id })

      expect(rdv_plan.reload.motif_id).not_to eq motif_from_other_organisation.id

      expect(flash[:error]).to be_present
    end
  end
end
