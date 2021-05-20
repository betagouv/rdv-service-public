# frozen_string_literal: true

describe "Admin can configure the organisation" do
  it "displays all the stats" do
    organisation = create(:organisation)
    agent_admin = create(:agent, admin_role_in_organisations: [organisation])
    login_as(agent_admin, scope: :agent)
    visit authenticated_agent_root_path
    click_link "Statistiques de l'organisation"
    expect(page).to have_content("Statistiques")
    expect(page).to have_content("RDV créés")
    expect(page).to have_content("Usagers créés")
  end
end
