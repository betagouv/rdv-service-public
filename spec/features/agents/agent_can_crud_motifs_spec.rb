RSpec.describe "Agent can CRUD motifs" do
  let(:organisation) { create(:organisation) }
  let!(:service) { create(:service, name: "PMI", territories: [organisation.territory]) }
  let!(:motif) { create(:motif, name: "Suivi bonjour", service: service, organisation: organisation) }
  let!(:agent) { create(:agent, service: service, admin_role_in_organisations: [organisation]) }

  before do
    login_as(agent, scope: :agent)
  end

  it "works" do
    visit authenticated_agent_root_path
    click_link "Motifs"
    expect_page_title("Vos motifs")
    click_link motif.name

    expect(page).to have_content(motif.name)
    click_link "Éditer"

    expect_page_title("Modifier le motif")
    fill_in "Nom", with: "Suivi bonsoir"
    click_button("Enregistrer")

    expect(page).to have_content("Suivi bonsoir")
    click_link("Supprimer")

    expect_page_title("Vos motifs")
    expect(page).to have_content("Vous n'avez pas encore créé de motif.")
    click_link "Créer un motif", match: :first

    expect_page_title("Création d’un nouveau motif")
    find("#motif_service_id").find(:option, service.name).select_option
    fill_in "Nom", with: "Suivi bonne nuit"
    fill_in "Couleur associée", with: "#000"
    click_button "Créer le motif"

    expect_page_title("Vos motifs")
    expect(page).to have_content("Suivi bonne nuit")
  end

  describe "new" do
    it "displays errors when name and service are missing" do
      visit new_admin_organisation_motif_path(organisation_id: organisation.id)
      click_on "Créer le motif"
      expect(page).to have_content("Nom doit être rempli(e)")
      expect(page).to have_content("Service doit exister")
    end
  end

  describe "edit" do
    it "displays errors when name and service are missing" do
      visit edit_admin_organisation_motif_path(organisation_id: organisation.id, id: motif.id)
      fill_in "Nom", with: ""
      select "", from: "Service associé"
      click_on "Enregistrer"
      expect(page).to have_content("Nom doit être rempli(e)")
      expect(page).to have_content("Service doit exister")
    end

    it "ensures that secretariat and followup cannot be simultaneously checked", js: true do
      visit edit_admin_organisation_motif_path(organisation_id: organisation.id, id: motif.id)
      click_on "Réservation en ligne"
      check "Autoriser les agents du service Secrétariat à assurer ces RDV"
      click_on "Enregistrer" and motif.reload
      expect(motif.for_secretariat).to be_truthy
      expect(motif.follow_up).to be_falsey

      click_on "Éditer"
      click_on "Réservation en ligne"
      check "Autoriser ces rendez-vous seulement aux usagers bénéficiant d'un suivi par un référent"
      expect(find("#motif_for_secretariat")).to be_disabled
      expect(find("#motif_for_secretariat")).not_to be_checked
      click_on "Enregistrer" and motif.reload
      expect(motif.for_secretariat).to be_falsey
      expect(motif.follow_up).to be_truthy
    end
  end
end
