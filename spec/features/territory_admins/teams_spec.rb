RSpec.describe "Managing teams" do
  let(:current_agent) { create(:agent) }
  let!(:rights) do
    create :agent_territorial_access_right, agent: current_agent, territory: territory, allow_to_manage_teams: true
  end
  let(:territory) { create(:territory) }

  before do
    login_as(current_agent, scope: :agent)
  end

  it "allows creating, editing and deleting teams" do
    visit admin_territory_path(territory.id)
    click_on "Équipes"
    click_on "Ajouter une équipe"
    fill_in "Nom", with: "Désecto Valence"
    click_on "Enregistrer"
    expect(page).to have_content "Désecto Valence"
    expect(Team.last).to have_attributes(
      territory_id: territory.id,
      name: "Désecto Valence"
    )
  end

  it "doesn't allow seeing teams in another territory" do
    other_territory = create(:territory)
    create(:team, territory: other_territory, name: "Equipe d'un autre territoire")

    visit admin_territory_teams_path(territory_id: other_territory.id)
    expect(page).not_to have_content("Equipe d'un autre territoire")
  end
end
