# frozen_string_literal: true

describe "Agent can see his stats" do
  it "displays all the stats" do
    agent = create(:agent, basic_role_in_organisations: [create(:organisation)])
    login_as(agent, scope: :agent)
    visit authenticated_agent_root_path
    click_link "Mes statistiques"
    expect(page).to have_content("Statistiques")
    expect(page).to have_content("RDV créés")
  end
end
