# frozen_string_literal: true

describe "territory admin can manage agents", type: :feature do
  let(:territory) { create(:territory, departement_number: "62") }
  let(:organisation) { create(:organisation, territory: territory) }

  describe "listing agents" do
    it "works" do
      zarg = create(:agent, last_name: "Zarg", admin_role_in_organisations: [organisation], role_in_territories: [territory])
      create(:agent_territorial_access_right, agent: zarg, territory: territory)
      blot = create(:agent, last_name: "Blot", basic_role_in_organisations: [organisation])
      create(:agent_territorial_access_right, agent: blot, territory: territory)
      login_as(zarg, scope: :agent)

      visit admin_territory_agents_path(territory_id: territory.id)
      expect(page).to have_content(zarg.email)
      expect(page).to have_content(blot.email)

      fill_in :q, with: "zarg"
      click_on "Rechercher"
      expect(page).to have_content(zarg.email)
      expect(page).not_to have_content(blot.email)

      fill_in :q, with: "autre"
      click_on "Rechercher"
      expect(page).not_to have_content(zarg.email)
      expect(page).not_to have_content(blot.email)
    end
  end

  describe "removing an agent from a team" do
    it "works" do
      team_a = create(:team, name: "A", territory: territory)
      team_b = create(:team, name: "B", territory: territory)
      current_agent = create(:agent, admin_role_in_organisations: [organisation], role_in_territories: [territory], teams: [team_a])
      agent = create(:agent, admin_role_in_organisations: [organisation], role_in_territories: [territory], teams: [team_a, team_b])
      create(:agent_territorial_access_right, agent: current_agent, territory: territory, allow_to_manage_teams: true)
      login_as(current_agent, scope: :agent)

      visit edit_admin_territory_agent_path(territory_id: territory.id, id: agent.id)
      unselect team_a.name, from: "Équipes"
      expect { click_on "Enregistrer" }.to change { agent.reload.teams.map(&:name).sort }.from(%w[A B]).to(["B"])
    end
  end
end
