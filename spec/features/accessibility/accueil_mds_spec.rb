# frozen_string_literal: true

describe "accueil_mds", js: true do
  it "root path page is accessible" do
    expect_page_to_be_axe_clean(accueil_mds_path)
  end

  it "agent agenda path page is accessible" do
    territory = create(:territory, departement_number: "75")
    organisation = create(:organisation, territory: territory)

    agent = create(:agent, email: "totoagent@example.com", basic_role_in_organisations: [organisation])
    login_as agent

    path = admin_organisation_agent_agenda_path(organisation, agent.id)
    expect_page_to_be_axe_clean(path)
  end
end
