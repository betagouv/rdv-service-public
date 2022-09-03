# frozen_string_literal: true

describe "agents page", js: true do
  it "login is accessible" do
    path = new_agent_session_path
    expect_page_to_be_axe_clean(path)
  end

  it "agent agenda path page is accessible" do
    territory = create(:territory, departement_number: "75")
    organisation = create(:organisation, territory: territory)
    agent = create(:agent, email: "totoagent@example.com", basic_role_in_organisations: [organisation])
    login_as agent

    path = admin_organisation_agent_agenda_path(organisation, agent)
    expect_page_to_be_axe_clean(path)
  end

  it "admin organisation user path is accessible" do
    territory = create(:territory, departement_number: "75")
    organisation = create(:organisation, territory: territory)
    user = create(:user, email: "testuser@test.net", agents: [], organisations: [organisation])
    agent = create(:agent, email: "totoagent@example.com", basic_role_in_organisations: [organisation])
    login_as agent

    path = admin_organisation_user_path(organisation, user)
    expect_page_to_be_axe_clean(path)
  end

  it "agents preferences path is accessible" do
    territory = create(:territory, departement_number: "75")
    organisation = create(:organisation, territory: territory)
    agent = create(:agent, email: "totoagent@example.com", basic_role_in_organisations: [organisation])
    login_as agent
    expect_page_to_be_axe_clean(agents_preferences_path)
  end
end
