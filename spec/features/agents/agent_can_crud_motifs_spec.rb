RSpec.describe "Agent can CRUD motifs" do
  let(:organisation) { create(:organisation) }
  let!(:service) { create(:service, name: "PMI", territories: [organisation.territory]) }
  let!(:motif) { create(:motif, name: "Suivi bonjour", service: service, organisation: organisation) }
  let!(:agent) { create(:agent, service: service, admin_role_in_organisations: [organisation]) }

  before do
    login_as(agent, scope: :agent)
    visit authenticated_agent_root_path
    click_link "Motifs"
  end

  it "works" do
    expect_page_title("Vos motifs")
    click_link motif.name

    expect(page).to have_content(motif.name)
    click_link "Éditer"

    expect_page_title("Modifier le motif")
    fill_in "Intitulé du motif", with: "Suivi bonsoir"
    click_button("Enregistrer")

    expect(page).to have_content("Suivi bonsoir")
    click_link("Supprimer")

    expect_page_title("Vos motifs")
    expect(page).to have_content("Vous n'avez pas encore créé de motif.")
    click_link "Créer un motif", match: :first

    expect_page_title("Création d’un nouveau motif")
    find("#motif_service_id").find(:option, service.name).select_option
    fill_in "Intitulé du motif", with: "Suivi bonne nuit"
    fill_in "Couleur associée", with: "#000"
    click_button "Enregistrer"

    expect_page_title("Vos motifs")
    expect(page).to have_content("Suivi bonne nuit")
  end

  describe "new" do
    it "displays errors when name and service are missing" do
      visit new_admin_organisation_motif_path(organisation_id: organisation.id)
      click_on "Enregistrer"
      expect(page).to have_content("Nom doit être rempli(e)")
      expect(page).to have_content("Service doit exister")
    end
  end

  describe "edit" do
    it "displays errors when name and service are missing" do
      visit edit_admin_organisation_motif_path(organisation_id: organisation.id, id: motif.id)
      fill_in "Intitulé du motif", with: ""
      select "", from: "Service associé"
      click_on "Enregistrer"
      expect(page).to have_content("Nom doit être rempli(e)")
      expect(page).to have_content("Service doit exister")
    end
  end
end
