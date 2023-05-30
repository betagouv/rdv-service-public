# frozen_string_literal: true

describe "agents page", js: true do
  it "login is accessible" do
    path = new_agent_session_path
    expect_page_to_be_axe_clean(path)
  end

  it "agenda without event page is accessible" do
    territory = create(:territory, departement_number: "75")
    organisation = create(:organisation, territory: territory)
    agent = create(:agent, email: "totoagent@example.com", basic_role_in_organisations: [organisation])
    login_as agent

    path = admin_organisation_agent_agenda_path(organisation, agent)
    expect_page_to_be_axe_clean(path)
  end

  it "agenda with 3 rdvs is accessible" do
    travel_to(Time.current.beginning_of_week.change(hour: 13))
    territory = create(:territory, departement_number: "75")
    organisation = create(:organisation, territory: territory)
    agent = create(:agent, email: "totoagent@example.com", basic_role_in_organisations: [organisation])
    create_list(:rdv, 3, agents: [agent], starts_at: 2.days.from_now)
    login_as agent, scope: :agent

    path = admin_organisation_agent_agenda_path(organisation, agent)

    visit path
    expect(page).to have_current_path(path)
    expect(page).to have_content(Rdv.last.users.last.full_name)
    expect(page).to be_axe_clean
  end

  it "admin organisation plage_ouvertures path is accessible" do
    territory = create(:territory, departement_number: "75")
    organisation = create(:organisation, territory: territory)
    agent = create(:agent, email: "totoagent@example.com", basic_role_in_organisations: [organisation])
    create_list(:plage_ouverture, 3, agent: agent)
    login_as agent

    path = admin_organisation_agent_plage_ouvertures_path(organisation, agent)
    expect_page_to_be_axe_clean(path)
  end

  xit "admin organisation users path is accessible" do
    territory = create(:territory, departement_number: "75")
    organisation = create(:organisation, territory: territory)
    create_list(:user, 3, organisations: [organisation])
    agent = create(:agent, email: "totoagent@example.com", basic_role_in_organisations: [organisation])
    login_as agent

    path = admin_organisation_users_path(organisation)
    expect_page_to_be_axe_clean(path)
  end

  it "admin organisation user path is accessible" do
    territory = create(:territory, departement_number: "75")
    organisation = create(:organisation, territory: territory)
    user = create(:user, email: "testuser@test.net", referent_agents: [], organisations: [organisation])
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

  it "RDV list is accessible" do
    territory = create(:territory, departement_number: "75")
    organisation = create(:organisation, territory: territory)
    agent = create(:agent, email: "totoagent@example.com", basic_role_in_organisations: [organisation])
    login_as agent
    create_list(:rdv, 3, agents: [agent])
    expect_page_to_be_axe_clean(admin_organisation_rdvs_path(organisation))
  end
end
