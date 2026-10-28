RSpec.describe "Un agent qui s'est self-onboardé puis a fermé son organisation" do
  let(:agent) { create(:agent, email: "radia@ac-lyon.fr") }

  it "est redirigé vers la liste des organisations de son espace, où il peut rouvrir son organisation" do
    # Self-onboarding : l'agent ouvre un espace avec une organisation
    login_as(agent, scope: :agent)
    visit new_agents_territory_path
    fill_in "Nom de votre organisation", with: "École Centrale de Lyon"
    click_on "Enregistrer"
    organisation = agent.organisations.last
    territory = agent.territories.last
    # L'agent ferme l'organisation tout juste créée
    visit admin_organisation_path(organisation)
    click_on "Fermer #{organisation.name}"
    expect(page).to have_content("L'organisation a été fermée.")
    expect(organisation.reload.disabled_at).to be_present
    # il est alors redirigé vers la page d'administration de son territoire
    visit authenticated_agent_root_path
    expect(page).to have_current_path(admin_territory_organisations_path(territory))
    expect(page).to have_content("Organisations fermées")
    # Il peut rouvrir son organisation fermée
    click_on organisation.name
    click_on "Réouvrir cette organisation"
    expect(page).to have_content("Organisation rouverte !")
    expect(organisation.reload.disabled_at).to be_nil
  end
end
