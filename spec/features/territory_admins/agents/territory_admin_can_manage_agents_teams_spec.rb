# Ces feature specs sont complétées par des specs sur les permissions dans spec/controllers/admin/territories/agent_territorial_access_rights_controller_spec.rb

RSpec.describe "territory admin can manage agents", type: :feature do
  let(:territory) { create(:territory) }
  let(:organisation) { create(:organisation, territory: territory) }

  describe "removing an agent from a team" do
    it "works" do
      team_a = create(:team, name: "A", territory: territory)
      team_b = create(:team, name: "B", territory: territory)
      current_agent = create(:agent, admin_role_in_organisations: [organisation], admin_in_territories: [], teams: [team_a])
      agent = create(:agent, admin_role_in_organisations: [organisation], admin_in_territories: [], teams: [team_a, team_b])
      create(:agent_territorial_access_right, agent: current_agent, territory: territory, allow_to_manage_teams: true)
      create(:agent_territorial_access_right, agent: agent, territory: territory)
      login_as(current_agent, scope: :agent)

      visit edit_admin_territory_agent_path(territory_id: territory.id, id: agent.id)
      unselect team_a.name, from: "Équipes"
      expect { click_on "Enregistrer" }.to change { agent.reload.teams }.to([team_b])
    end
  end
end
