RSpec.describe "Update territory admin" do
  let(:territory) { create(:territory) }
  let(:current_agent) { create(:agent, role_in_territories: []) }
  let(:other_agent) { create(:agent) }
  let(:organisation) { create(:organisation, territory: territory) }

  before do
    create(:agent_territorial_access_right, agent: other_agent)
  end

  before { sign_in current_agent }

  context "when the agent can only manage teams in the current territory" do
    before do
      create(:agent_territorial_access_right, agent: current_agent, territory: territory, allow_to_manage_teams: true)
    end

    it "doesn't allow making an agent a territorial admin" do
      put create_or_destroy_admin_territory_agent_territorial_roles_path(territory_id: territory.id, agent_id: other_agent.id), params: { territorial_admin: "1" }
      expect(other_agent.reload.territorial_roles).to be_empty
    end
  end

  context "quand l'agent est admin de territoire" do
    let(:current_agent) { create(:agent, role_in_territories: [territory]) }
    let(:other_agent) { create(:agent, basic_role_in_organisations: [organisation]) }

    before { stub_const("AgentSensitiveAccountCalculator::SENSITIVE_RDV_THRESHOLD", 2) }

    it "marque immédiatement l'agent comme sensible, sans attendre le job quotidien" do
      create_list(:rdv, 3, organisation: organisation)

      put create_or_destroy_admin_territory_agent_territorial_roles_path(territory_id: territory.id, agent_id: other_agent.id), params: { territorial_admin: "1" }

      expect(other_agent.reload.territorial_roles).not_to be_empty
      expect(other_agent.sensitive_account).to be true
    end
  end
end
