# frozen_string_literal: true

describe "Admin can configure the organisation" do
  specify do
    organisation = create(:organisation)
    agent = create(:agent, organisations: [organisation])
    plage_ouverture = create(:plage_ouverture, agent: agent, organisation: organisation)

    login_as agent

    visit admin_organisation_agent_plage_ouvertures_path(organisation, agent)

    expect(page).to have_content(plage_ouverture.title)

    click_on("Supprimer")
    expect(page).not_to have_content(plage_ouverture.title)
  end
end
