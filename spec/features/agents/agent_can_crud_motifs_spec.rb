RSpec.describe "Agent can CRUD motifs" do
  let(:organisation) { create(:organisation) }
  let!(:service) { create(:service, name: "PMI", territories: [organisation.territory]) }
  let!(:motif) { create(:motif, name: "Suivi bonjour", service: service, organisation: organisation, bookable_by: "agents") }
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

    it "unchecks for_secretariat when checking followup", :js do
      visit edit_admin_organisation_motif_path(organisation_id: organisation.id, id: motif.id)
      find("#tab_resa_en_ligne").click
      check "Autoriser les agents du service Secrétariat à assurer ces RDV"
      click_on "Enregistrer" and motif.reload
      expect(motif.for_secretariat).to be_truthy
      expect(motif.follow_up).to be_falsey

      click_on "Éditer"
      find("#tab_resa_en_ligne").click
      check "Autoriser ces rendez-vous seulement aux usagers bénéficiant d'un suivi par un référent"
      expect(find("#motif_for_secretariat", visible: false)).not_to be_checked
      click_on "Enregistrer" and motif.reload
      expect(motif.for_secretariat).to be_falsey
      expect(motif.follow_up).to be_truthy
    end

    it "automatically checks and unchecks rdvs_editable_by_user when toggling online reservation", :js do
      # On ouvre le motif à la résa en ligne, la case "RDVs modifiables" est cochée automatiquement
      visit edit_admin_organisation_motif_path(organisation_id: organisation.id, id: motif.id)
      find("#tab_resa_en_ligne").click

      # On ouvre à la résa en ligne, la case est cochée
      choose "Agents de l’organisation, prescripteurs et usagers"
      editable_by_user_checkbox = find("#motif_rdvs_editable_by_user")
      expect(editable_by_user_checkbox).to be_checked

      # On ferme à la résa en ligne, la case est décochée
      choose "Agents de l’organisation", id: "motif_bookable_by_agents"
      expect(editable_by_user_checkbox).not_to be_checked

      # On ouvre à la résa en ligne, la case est cochée
      choose "Agents de l’organisation, prescripteurs et usagers"
      expect(editable_by_user_checkbox).to be_checked

      expect { click_on "Enregistrer" }.to change { motif.reload.bookable_by }.to("everyone")

      # On décoche la case "RDVs modifiables" et on enregistre
      click_on "Éditer"
      find("#tab_resa_en_ligne").click
      uncheck "motif_rdvs_editable_by_user"
      expect { click_on "Enregistrer" }.to change { motif.reload.rdvs_editable_by_user }.from(true).to(false)

      # On revient sur le formulaire, la case est bien décochée
      # et reste décochée lorsque l'on désactive la résa en ligne
      click_on "Éditer"
      find("#tab_resa_en_ligne").click
      expect(editable_by_user_checkbox).not_to be_checked
      choose "Agents de l’organisation", id: "motif_bookable_by_agents"
      expect(editable_by_user_checkbox).not_to be_checked
      expect { click_on "Enregistrer" }.to change { motif.reload.bookable_by }.from("everyone").to("agents")
    end
  end
end
