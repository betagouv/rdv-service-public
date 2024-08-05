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
      expect do
        put create_or_destroy_admin_territory_agent_territorial_roles_path(territory_id: territory.id, agent_id: other_agent.id), params: { territorial_admin: "1" }
      end.to raise_error(ActiveRecord::RecordNotFound)
      expect(other_agent.reload.territorial_roles).to be_empty
    end
  end
end
