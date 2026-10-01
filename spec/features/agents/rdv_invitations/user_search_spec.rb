RSpec.describe "Recherche d'usager pour les invitations" do
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let(:organisation) { create(:organisation) }

  let!(:user) { create(:user, :francis_factice, organisations: [organisation]) }

  before { login_as agent, scope: :agent }

  it "permet de chercher parmis les usagers de l'organisation", js: true do
    visit edit_user_admin_organisation_rdv_invitations_path(organisation)

    expect(page).to have_content("Cherchez un usager par nom, prénom, téléphone, ou email")
    sleep 0.3 # Pour attendre le chargement du composant
    find(".select2-search__field").send_keys("fra")

    expect(page).to have_content("FACTICE Francis")
    find(".select2-results__option", text: "FACTICE Francis", match: :first).click

    # On est redirigé vers la page suivante
    expect(page).to have_content("Étape 2 sur 3")
    expect(page).to have_content("Nous allons envoyer une invitation à Francis FACTICE")
  end

  it "incite à ajouter un usager s'il n'en trouve pas", js: true do
    visit edit_user_admin_organisation_rdv_invitations_path(organisation)

    expect(page).to have_content("Cherchez un usager par nom, prénom, téléphone, ou email")
    sleep 0.3 # Pour attendre le chargement du composant
    find(".select2-search__field").send_keys("un nom qui n'existe pas")

    # On fait du bouton tertiaire un bouton primaire pour attirer l'attention de l'agent
    expect(page).to have_css('[aria-controls="new-user-modal"].fr-btn')
    expect(page).not_to have_css('[aria-controls="new-user-modal"].fr-btn.fr-btn--tertiary--no-outline')
  end

  context "quand l'usager appartient au territoire mais pas à l'organisation" do
    let(:other_organisation) do
      create(:organisation, territory: organisation.territory)
    end
    let!(:user) { create(:user, :francis_factice, organisations: [other_organisation]) }

    it "permet de le sélectionner" do
      visit edit_user_admin_organisation_rdv_invitations_path(organisation)

      expect(page).to have_content("Cherchez un usager par nom, prénom, téléphone, ou email")
      sleep 0.3 # Pour attendre le chargement du composant
      find(".select2-search__field").send_keys("fra")

      find(".select2-results__option", text: "FACTICE Francis", match: :first).click

      # On est redirigé vers la page suivante
      expect(page).to have_content("Étape 2 sur 3")
    end
  end
end
