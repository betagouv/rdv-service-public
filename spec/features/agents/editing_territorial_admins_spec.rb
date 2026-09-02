RSpec.describe "Admin can configure the organisation" do
  let(:territory) { create(:territory) }
  let(:organisation) { create(:organisation, territory: territory) }

  let(:agent) { create(:agent, basic_role_in_organisations: [organisation], admin_in_territories: [territory]) }
  let(:other_agent) { create(:agent, basic_role_in_organisations: [organisation], admin_in_territories: []) }
  let!(:other_agent_access_right) { create(:agent_territorial_access_right, allow_to_manage_access_rights: false, territory: territory, agent: other_agent) }

  before { login_as(agent, scope: :agent) }

  it "can give territorial admin access to other agent" do
    visit edit_admin_territory_agent_path(territory, other_agent)
    check("Administrateur de #{territory.name_for_agent}")
    expect { click_on("Enregistrer les droits d'accès") }.to change { other_agent.reload.territorial_admin_in?(territory) }.to(true)
  end

  it "can't remove the last territorial admin" do
    visit edit_admin_territory_agent_path(territory, agent)
    uncheck("Administrateur de #{territory.name_for_agent}")
    click_on("Enregistrer les droits d'accès")

    expect(page).to have_content "Il doit toujours y avoir au moins un agent responsable par espace"
    expect(agent.reload.territorial_admin_in?(territory)).to be true
  end
end
