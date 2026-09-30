RSpec.describe "Recherche d'usager pour les invitations" do
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let(:organisation) { create(:organisation) }

  let!(:user) { create(:user, :francis_factice, organisations: [organisation]) }

  before { login_as agent, scope: :agent }

  it "permet de chercher parmis les usagers de l'organisation", js: true do
    visit edit_user_admin_organisation_rdv_invitations_path(organisation)

    expect(page).to have_content("Cherchez un usager par nom, prénom, téléphone, ou email")
    sleep 1
    find(".select2-search__field").send_keys("fra")

    expect(page).to have_content("FACTICE Francis")
    find(".select2-results__option", text: "FACTICE Francis", match: :first).click

    # On est redirigé vers la page suivante
    expect(page).to have_content("Étape 2 sur 3")
    expect(page).to have_content("Nous allons envoyer une invitation à Francis FACTICE")
  end
end
