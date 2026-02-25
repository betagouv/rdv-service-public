RSpec.describe "Agent can CRUD motifs" do
  let(:organisation) { create(:organisation) }
  let!(:service) { create(:service, name: "PMI", territories: [organisation.territory]) }
  let!(:motif) { create(:motif, name: "Suivi bonjour", service: service, organisation: organisation, bookable_by: "agents") }
  let!(:agent) { create(:agent, service: service, admin_role_in_organisations: [organisation]) }

  before do
    login_as(agent, scope: :agent)
  end

  context "with a service" do
    it "works" do
      visit authenticated_agent_root_path
      click_link "Configuration"
      click_link "Motifs"
      expect_page_title("Motifs de rendez-vous")
      click_link motif.name

      expect(page).to have_content(motif.name)
      click_link "Modifier"

      expect_page_title("Modifier le motif")
      fill_in "Nom", with: "Suivi bonsoir"
      click_button("Enregistrer")

      expect(page).to have_content("Suivi bonsoir (PMI)")
      click_on("Archiver")
      expect(page).to have_content("Suivi bonsoir (PMI) (archivé)")
      click_on("Supprimer")

      expect_page_title("Motifs de rendez-vous")
      expect(page).to have_content("Vous n'avez pas encore créé de motif.")
      click_link "Créer un motif", match: :first

      expect_page_title("Créer un motif")
      ## Check secretariat is unavailable
      expect(page.all("select#motif_service_id option").map(&:value)).to contain_exactly("", service.id.to_s)
      find("#motif_service_id").find(:option, service.name).select_option
      fill_in "Nom", with: "Suivi bonne nuit"
      fill_in "Couleur associée", with: "#000"
      click_button "Créer le motif"

      expect_page_title("Motifs de rendez-vous")
      expect(page).to have_content("Suivi bonne nuit")
    end
  end

  context "without a service" do
    let!(:motif) { nil }

    it "works" do
      visit new_admin_organisation_motif_path(organisation_id: organisation.id)

      expect_page_title("Créer un motif")

      fill_in "Nom", with: "Demande de permis de construire"
      fill_in "Couleur associée", with: "#000"
      fill_in "Durée du RDV (en minutes)", with: "15"
      click_button "Créer le motif"

      expect_page_title("Motifs de rendez-vous")

      expect(organisation.motifs.count).to eq 1
      expect(page).to have_content("Demande de permis de construire")

      click_link "Modifier"

      expect_page_title("Modifier le motif")
      fill_in "Nom", with: "Renouvellement de permis de construire"
      click_button("Enregistrer")

      expect(page).to have_content("Renouvellement de permis de construire")
      click_on("Archiver")
      expect(page).to have_content("Renouvellement de permis de construire (archivé)")
      click_on("Supprimer")
    end

    context "when the territory doesn't have any services" do
      let!(:service) { nil }

      it "doesn't display the service field or information" do
        visit new_admin_organisation_motif_path(organisation_id: organisation.id)
        expect(page).not_to have_content("Service")

        fill_in "Nom", with: "Demande de permis de construire"
        fill_in "Couleur associée", with: "#000"
        fill_in "Durée du RDV (en minutes)", with: "15"
        click_button "Créer le motif"

        expect_page_title("Motifs de rendez-vous")

        visit admin_organisation_motif_path(organisation_id: organisation.id, id: Motif.last.id)
        expect(page).not_to have_content("Service")
      end
    end
  end

  describe "new" do
    it "displays errors when name and service are missing" do
      visit new_admin_organisation_motif_path(organisation_id: organisation.id)
      click_on "Créer le motif"
      expect(page).to have_content("Nom doit être rempli·e")
    end
  end

  describe "edit" do
    it "displays errors when name and service are missing" do
      visit edit_admin_organisation_motif_path(organisation_id: organisation.id, id: motif.id)
      fill_in "Nom", with: ""
      click_on "Enregistrer"
      expect(page).to have_content("Nom doit être rempli·e")
    end

    it "unchecks for_secretariat when checking followup", js: true do
      visit edit_admin_organisation_motif_path(organisation_id: organisation.id, id: motif.id)
      find("#tab_resa_en_ligne").click
      check "Autoriser les agents du service Secrétariat à assurer ces RDV", allow_label_click: true
      click_on "Enregistrer"
      expect(page).to have_content "Le motif #{motif.name} a été modifié."
      motif.reload
      expect(motif.for_secretariat).to be_truthy
      expect(motif.follow_up).to be_falsey

      click_on "Modifier"
      find("#tab_resa_en_ligne").click
      check "Autoriser ces rendez-vous seulement aux usagers bénéficiant d'un suivi par un référent", allow_label_click: true
      expect(find("#motif_for_secretariat", visible: false)).not_to be_checked
      click_on "Enregistrer"
      expect(page).to have_content "Le motif #{motif.name} a été modifié."
      motif.reload
      expect(motif.for_secretariat).to be_falsey
      expect(motif.follow_up).to be_truthy
    end

    it "automatically checks and unchecks rdvs_editable_by_user when toggling online reservation", js: true do
      # On ouvre le motif à la résa en ligne, la case "RDVs modifiables" est cochée automatiquement
      visit edit_admin_organisation_motif_path(organisation_id: organisation.id, id: motif.id)
      find("#tab_resa_en_ligne").click

      # On ouvre à la résa en ligne, la case est cochée
      choose "Agents de l’organisation, prescripteurs et usagers", allow_label_click: true
      expect(page).to have_content "RDVs modifiables"
      editable_by_user_checkbox = find("#motif_rdvs_editable_by_user", visible: false)
      expect(editable_by_user_checkbox).to be_checked

      # On ferme à la résa en ligne, la case est décochée
      choose "Agents de l’organisation", id: "motif_bookable_by_agents", allow_label_click: true
      expect(editable_by_user_checkbox).not_to be_checked

      # On ouvre à la résa en ligne, la case est cochée
      choose "Agents de l’organisation, prescripteurs et usagers", allow_label_click: true
      expect(editable_by_user_checkbox).to be_checked

      expect do
        click_on "Enregistrer"
        expect(page).to have_content "Le motif #{motif.name} a été modifié."
      end.to change { motif.reload.bookable_by }.to("everyone")

      # On décoche la case "RDVs modifiables" et on enregistre
      click_on "Modifier"
      find("#tab_resa_en_ligne").click
      uncheck "motif_rdvs_editable_by_user", allow_label_click: true
      expect do
        click_on "Enregistrer"
        expect(page).to have_content "Le motif #{motif.name} a été modifié."
      end.to change { motif.reload.rdvs_editable_by_user }.from(true).to(false)

      # On revient sur le formulaire, la case est bien décochée
      # et reste décochée lorsque l'on désactive la résa en ligne
      click_on "Modifier"
      find("#tab_resa_en_ligne").click
      expect(editable_by_user_checkbox).not_to be_checked
      choose "Agents de l’organisation", id: "motif_bookable_by_agents", allow_label_click: true
      expect(editable_by_user_checkbox).not_to be_checked
      expect do
        click_on "Enregistrer"
        expect(page).to have_content "Le motif #{motif.name} a été modifié." # On attend le chargement de cette page pour éviter une flaky spec
      end.to change { motif.reload.bookable_by }.from("everyone").to("agents")
    end

    it "allows changing the motif's location_type to :visio" do
      motif = create(:motif, organisation: organisation, location_type: :public_office, service:)

      visit admin_organisation_motifs_path(organisation)
      click_on motif.name
      click_on "Modifier"
      expect(page).to have_content "L'agent et l'usager se retrouvent sur un lien de visioconférence unique pour chaque RDV."
      choose "Par visioconférence"
      expect { click_on "Enregistrer" }.to change { motif.reload.location_type }.from("public_office").to("visio")
    end
  end

  describe "archiving" do
    it "can be done from the index page" do
      visit admin_organisation_motifs_path(motif.organisation)
      expect { click_on "Archiver" }.to change { motif.reload.archived? }.from(false).to(true)
      expect(page).to have_content("Le motif Suivi bonjour a été archivé")
    end

    it "can be done from the show page" do
      visit admin_organisation_motif_path(motif.organisation, motif)
      expect { click_on "Archiver" }.to change { motif.reload.archived? }.from(false).to(true)
      expect(page).to have_content("Le motif Suivi bonjour a été archivé")
    end

    context "when the motif is invalid" do
      it "archives anyway" do
        # fait échouer la validation :cant_be_for_secretariat_and_follow_up
        motif.update_columns(for_secretariat: true, follow_up: true) # rubocop:disable Rails/SkipsModelValidations
        expect(motif).to be_invalid

        visit admin_organisation_motif_path(motif.organisation, motif)
        expect { click_on "Archiver" }.to change { motif.reload.archived? }.from(false).to(true)
        expect(page).to have_content("Le motif Suivi bonjour a été archivé")
      end
    end
  end

  describe "un-archiving" do
    before do
      motif.archive
    end

    it "can be done from the index page in the dedicated tab" do
      visit admin_organisation_motifs_path(motif.organisation, current_tab: "archived")
      expect { click_on "Réactiver" }.to change { motif.reload.archived? }.from(true).to(false)
      expect(page).to have_content("Le motif Suivi bonjour a été réactivé")
    end

    it "can be done from the show page" do
      visit admin_organisation_motif_path(motif.organisation, motif)
      expect { click_on "Réactiver" }.to change { motif.reload.archived? }.from(true).to(false)
      expect(page).to have_content("Le motif Suivi bonjour a été réactivé")
    end

    context "when an active duplicate exists" do
      before do
        duplicate = motif.dup
        duplicate.deleted_at = nil
        duplicate.public_link_id = SecureRandom.base58(8)
        duplicate.save!
      end

      it "explains why the motif can't be un-archived" do
        visit admin_organisation_motif_path(motif.organisation, motif)
        expect { click_on "Réactiver" }.not_to change { motif.reload.archived? }.from(true)
        expect(page).to have_content("Il existe déjà dans #{motif.organisation.name} un motif")
      end
    end
  end

  describe "destroying a motif" do
    context "when it was not used for any RDV" do
      it "removes it from the database" do
        motif.archive

        visit admin_organisation_motif_path(motif.organisation, motif)
        expect { click_on "Supprimer" }.to change { Motif.exists?(motif.id) }.from(true).to(false)
        expect(page).to have_content("Le motif Suivi bonjour a été supprimé")
      end
    end

    context "when it was used for some RDVs" do
      it "displays an error" do
        create_list(:rdv, 2, organisation: motif.organisation, motif: motif)

        visit admin_organisation_motif_path(motif.organisation, motif)
        expect { click_on "Supprimer" }.not_to change { Motif.exists?(motif.id) }.from(true)
        expect(page).to have_content("Impossible de supprimer le motif : il est lié à 2 rendez-vous.")
      end
    end
  end

  describe "when the next necessary step is to create a lieu" do
    let(:motif) { nil } # Pour éviter la création d'un motif par défaut

    it "recommends it in the flash confirmation" do
      visit new_admin_organisation_motif_path(organisation)
      fill_in("Nom du motif", with: "Accompagnement")
      select("PMI", from: "Service associé")
      fill_in("Couleur associée", with: "#000000")
      click_on("Créer le motif")

      expect(page).to have_content("Vous pouvez maintenant ajouter le lieu où vous allez faire vos rendez-vous.")
    end
  end
end
