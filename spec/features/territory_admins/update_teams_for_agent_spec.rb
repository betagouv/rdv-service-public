RSpec.describe "update an agent's teams" do
  let(:territory_admin) { create(:agent) }
  let(:agent) { create(:agent, basic_role_in_organisations: [orga]) }

  let(:territory) { create(:territory) }
  let(:other_territory) { create(:territory) }
  let(:orga) { create(:organisation, territory:) }

  let(:team) { create(:team, territory: territory, name: "Equipe actuelle") }
  let!(:other_team_in_first_territory)  { create(:team, territory: territory, name: "Nouvelle équipe") }
  let!(:other_team_in_other_territory)  { create(:team, territory: other_territory) }

  let(:multi_territory_agent) { create(:agent) }

  before do
    create(:agent_territorial_access_right, agent: territory_admin, territory: territory, allow_to_manage_teams: true)
    create(:agent_territorial_access_right, agent:, territory: territory)
    AgentTeam.create!(agent:, team:)
    AgentTeam.create!(agent:, team: other_team_in_other_territory)

    login_as(territory_admin, scope: :agent)
  end

  it "allows changing the agent teams in this territory" do
    visit edit_admin_territory_agent_path(agent.id, territory_id: territory.id)
    unselect "Equipe actuelle", from: "Équipes"
    select "Nouvelle équipe", from: "Équipes"

    click_on "Enregistrer"

    expect(page).to have_content("Les équipes de l’agent ont été mises à jour")
    expect(agent.reload.teams).to contain_exactly(other_team_in_first_territory, other_team_in_other_territory)
  end
end
