RSpec.describe "Admin can configure the organisation" do
  specify do
    organisation = create(:organisation)
    agent = create(:agent, organisations: [organisation])
    plage_ouverture = create(:plage_ouverture, agent: agent, organisation: organisation)

    login_as(agent, scope: :agent)

    visit admin_organisation_planning_plage_ouvertures_path(organisation)

    expect(page).to have_content(plage_ouverture.title_with_default)

    click_on("Supprimer")
    expect(page).not_to have_content(plage_ouverture.title_with_default)
  end
end
