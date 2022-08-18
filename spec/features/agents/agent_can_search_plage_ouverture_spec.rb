# frozen_string_literal: true

describe "Agent can search plage ouverture" do
  specify do
    organisation = create(:organisation)
    agent = create(:agent, organisations: [organisation])

    perm_enfance = create(:plage_ouverture, title: "Permanence Enfance", agent: agent, organisation: organisation)
    perm_scolaire = create(:plage_ouverture, title: "Permanence Scolaire", agent: agent, organisation: organisation)

    login_as(agent, scope: :agent)
    visit admin_organisation_agent_plage_ouvertures_path(organisation, agent)

    expect(page).to have_content(perm_enfance.title)
    expect(page).to have_content(perm_scolaire.title)

    fill_in :search, with: "sco"
    click_button "Rechercher"

    expect(page).not_to have_content(perm_enfance.title)
    expect(page).to have_content(perm_scolaire.title)
  end
end
