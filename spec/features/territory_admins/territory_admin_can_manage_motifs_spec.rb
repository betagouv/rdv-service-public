RSpec.describe "territory admin can manage motifs", type: :feature do
  let!(:territory) { create(:territory) }
  let!(:agent) { create(:agent, role_in_territories: [territory]) }

  before do
    login_as(agent, scope: :agent)
  end

  describe "Listing motifs" do
    let!(:org_arques) { create(:organisation, name: "Arques", territory: territory) }
    let!(:org_bapaume) { create(:organisation, name: "Bapaume", territory: territory) }
    let!(:motif_consultation_prenatale) { create(:motif, name: "Consultation prénatale", organisation: org_arques) }
    let!(:motif_suivi_apres_naissance) { create(:motif, name: "Suivi après naissance", organisation: org_bapaume) }

    before do
      agent.roles.create!(organisation: org_arques, access_level: AgentRole::ACCESS_LEVEL_ADMIN)
      agent.roles.create!(organisation: org_bapaume, access_level: AgentRole::ACCESS_LEVEL_ADMIN)
    end

    it "provides filtering" do
      visit admin_territory_motifs_path(territory)
      expect(page).to have_content("Consultation prénatale")
      expect(page).to have_content("Suivi après naissance")

      fill_in "Nom", with: "pre"
      click_on "Filtrer"
      expect(page).to have_content("Consultation prénatale")
      expect(page).not_to have_content("Suivi après naissance")

      select "Bapaume", from: "Organisation(s)"
      click_on "Filtrer"
      expect(page).to have_content("Aucun résultat")
    end

    it "displays archived motifs in separate tab" do
      visit admin_territory_motifs_path(territory)
      expect(page).to have_content("Consultation prénatale")
      expect(page).to have_content("Suivi après naissance")

      motif_suivi_apres_naissance.archive!
      visit admin_territory_motifs_path(territory)
      expect(page).to have_content("Consultation prénatale")
      expect(page).not_to have_content("Suivi après naissance")

      click_on "Archivés"
      expect(page).not_to have_content("Consultation prénatale")
      expect(page).to have_content("Suivi après naissance")
    end

    it "shows buttons to edit and delete" do
      visit admin_territory_motifs_path(territory)
      expect(page.body).to include(%(href="#{edit_admin_organisation_motif_path(org_arques, motif_consultation_prenatale)}"))
      expect(page.body).to include(%(href="#{edit_admin_organisation_motif_path(org_bapaume, motif_suivi_apres_naissance)}"))
    end

    context "when motifs exist in other organisations for which I am not admin" do
      let!(:org_autre) { create(:organisation, name: "Autre orga", territory: territory) }
      let!(:motif_autre_orga) { create(:motif, name: "Motif autre orga", organisation: org_autre) }

      it "is not shown in the list" do
        visit admin_territory_motifs_path(territory)
        expect(page).to have_content("Consultation prénatale")
        expect(page).not_to have_content("Motif autre orga")
      end
    end

    context "when motifs exist in another territory, which I admin" do
      let!(:org_autre_territoire) { create(:organisation, name: "Autre orga", territory: create(:territory)) }
      let!(:motif_autre_territoire) { create(:motif, name: "Motif autre territoire", organisation: org_autre_territoire) }

      before { agent.roles.create!(organisation: org_autre_territoire, access_level: AgentRole::ACCESS_LEVEL_ADMIN) }

      it "is not shown in the list" do
        visit admin_territory_motifs_path(territory)
        expect(page).to have_content("Consultation prénatale")
        expect(page).not_to have_content("Motif autre territoire")
      end
    end
  end

  describe "Creating a motif" do
    let!(:service_pmi) { create(:service, name: "PMI").tap { territory.services << _1 } }
    let!(:org_arques) { create(:organisation, name: "Arques", territory: territory) }
    let!(:org_bapaume) { create(:organisation, name: "Bapaume", territory: territory) }

    before do
      agent.roles.create!(organisation: org_arques, access_level: AgentRole::ACCESS_LEVEL_ADMIN)
      agent.roles.create!(organisation: org_bapaume, access_level: AgentRole::ACCESS_LEVEL_ADMIN)
    end

    it "works" do
      visit admin_territory_motifs_path(territory)
      click_on "Créer un motif"

      check "Arques"
      check "Bapaume"
      fill_in "Nom du motif", with: "Consultation prénatale"
      select "PMI", from: "Service associé"
      fill_in "Couleur associée", with: "#123456"

      expect { click_on "Créer le motif" }.to change(Motif, :count).by(2)
      expect(Motif.last(2)).to all(have_attributes({ name: "Consultation prénatale", service: service_pmi, color: "#123456" }))
    end

    context "when a motif already exists in one of the organisations" do
      before do
        create(:motif, :at_public_office, name: "Consultation prénatale", service: service_pmi, organisation: org_arques)
      end

      it "prevents creation and displays the error message" do
        visit admin_territory_motifs_path(territory)
        click_on "Créer un motif"

        check "Arques"
        check "Bapaume"
        fill_in "Nom du motif", with: "Consultation prénatale"
        select "PMI", from: "Service associé"
        fill_in "Couleur associée", with: "#123456"

        expect { click_on "Créer le motif" }.not_to change(Motif, :count)
        expect(page).to have_content("Un motif du même nom, même service et même type existe déjà dans Arques")
      end
    end
  end

  describe "batch edit" do
    let!(:organisation_a) { create(:organisation, territory: territory) }
    let!(:organisation_b) { create(:organisation, territory: territory) }
    let!(:organisation_c) { create(:organisation, territory: territory) }

    before do
      agent.roles.create!(organisation: organisation_a, access_level: AgentRole::ACCESS_LEVEL_ADMIN)
      agent.roles.create!(organisation: organisation_b, access_level: AgentRole::ACCESS_LEVEL_ADMIN)
      agent.roles.create!(organisation: organisation_c, access_level: AgentRole::ACCESS_LEVEL_ADMIN)
    end

    describe "motif selection" do
      let!(:motif_a) { create(:motif, organisation: organisation_a) }
      let!(:motif_b) { create(:motif, organisation: organisation_b) }
      let!(:motif_c) { create(:motif, organisation: organisation_c) }

      it "works manually", js: true do
        visit admin_territory_motifs_path(territory)
        find(%([type="checkbox"][value="#{motif_a.id}"])).check
        find(%([type="checkbox"][value="#{motif_c.id}"])).check
        click_on "Modifier les motifs"

        expect(page).to     have_content("Modifier les motifs")
        expect(page).to     have_content(motif_a.name)
        expect(page).not_to have_content(motif_b.name)
        expect(page).to     have_content(motif_c.name)

        # On vérifie qu'on arrive sur la page de modification en masse ;
        # cette page est testée dans les exemples ci-dessous.
        expect(page).to have_current_path(batch_edit_admin_territory_motifs_path(territory_id: territory.id, motif_ids: [motif_a.id, motif_c.id]))
      end

      it "works with batch check", js: true do
        visit admin_territory_motifs_path(territory)
        find("input.js-trigger-checkbox").check
        click_on "Modifier les motifs"

        expect(page).to have_content("Modifier les motifs")
        expect(page).to have_content(motif_a.name)
        expect(page).to have_content(motif_b.name)
        expect(page).to have_content(motif_c.name)

        # On vérifie qu'on arrive sur la page de modification en masse ;
        # cette page est testée dans les exemples ci-dessous.
        expect(page).to have_current_path(batch_edit_admin_territory_motifs_path(territory_id: territory.id, motif_ids: [motif_a.id, motif_b.id, motif_c.id]))
      end
    end

    describe "updating name" do
      let!(:motif_a) { create(:motif, organisation: organisation_a, name: "Nom avec faute A") }
      let!(:motif_b) { create(:motif, organisation: organisation_b, name: "Nom avec faute B") }

      it "works" do
        visit batch_edit_admin_territory_motifs_path(territory_id: territory.id, motif_ids: [motif_a.id, motif_b.id])

        within("#name_form") do
          fill_in "Nom du motif", with: "Nom corrigé"
          click_on "Appliquer"
          expect(motif_a.reload.name).to eq("Nom corrigé")
          expect(motif_b.reload.name).to eq("Nom corrigé")
        end
      end
    end

    describe "updating service" do
      let!(:service_pmi) { create(:service, :pmi).tap { territory.services << _1 } }
      let!(:service_social) { create(:service, :social).tap { territory.services << _1 } }
      let!(:motif_a) { create(:motif, organisation: organisation_a, service: service_pmi) }
      let!(:motif_b) { create(:motif, organisation: organisation_b, service: service_pmi) }

      it "works" do
        visit batch_edit_admin_territory_motifs_path(territory_id: territory.id, motif_ids: [motif_a.id, motif_b.id])

        within("#service_form") do
          select service_social.name, from: "Service"
          click_on "Appliquer"
          expect(motif_a.reload.service).to eq(service_social)
          expect(motif_b.reload.service).to eq(service_social)
        end
      end
    end

    describe "updating duration" do
      let!(:motif_a) { create(:motif, organisation: organisation_a, default_duration_in_min: 30) }
      let!(:motif_b) { create(:motif, organisation: organisation_b, default_duration_in_min: 60) }

      it "works" do
        visit batch_edit_admin_territory_motifs_path(territory_id: territory.id, motif_ids: [motif_a.id, motif_b.id])

        within("#duration_form") do
          fill_in "Durée par défaut en minutes", with: "45"
          click_on "Appliquer"
          expect(motif_a.reload.default_duration_in_min).to eq(45)
          expect(motif_b.reload.default_duration_in_min).to eq(45)
        end
      end
    end

    describe "updating color" do
      let!(:motif_a) { create(:motif, organisation: organisation_a, color: "#FFFFFF") }
      let!(:motif_b) { create(:motif, organisation: organisation_b, color: "#EEEEEE") }

      it "works" do
        visit batch_edit_admin_territory_motifs_path(territory_id: territory.id, motif_ids: [motif_a.id, motif_b.id])

        # Voir https://youtu.be/B0hpCzggOLM, si vous aviez la ref, bravo !
        within("#color_form") do
          fill_in "Couleur", with: "#000000"
          click_on "Appliquer"
          expect(motif_a.reload.color).to eq("#000000")
          expect(motif_b.reload.color).to eq("#000000")
        end
      end
    end

    describe "updating restriction_for_rdv" do
      let!(:motif_a) { create(:motif, organisation: organisation_a, restriction_for_rdv: "toto") }
      let!(:motif_b) { create(:motif, organisation: organisation_b, restriction_for_rdv: "tata") }

      it "works" do
        visit batch_edit_admin_territory_motifs_path(territory_id: territory.id, motif_ids: [motif_a.id, motif_b.id])

        within("#restriction_for_rdv_form") do
          fill_in "Instructions à accepter avant la prise du rendez-vous", with: "titi"
          click_on "Appliquer"
          expect(motif_a.reload.restriction_for_rdv).to eq("titi")
          expect(motif_b.reload.restriction_for_rdv).to eq("titi")
        end
      end
    end

    describe "updating instruction_for_rdv" do
      let!(:motif_a) { create(:motif, organisation: organisation_a, instruction_for_rdv: "toto") }
      let!(:motif_b) { create(:motif, organisation: organisation_b, instruction_for_rdv: "tata") }

      it "works" do
        visit batch_edit_admin_territory_motifs_path(territory_id: territory.id, motif_ids: [motif_a.id, motif_b.id])

        within("#instruction_for_rdv_form") do
          fill_in "Indications affichées après la confirmation du rendez-vous", with: "titi"
          click_on "Appliquer"
          expect(motif_a.reload.instruction_for_rdv).to eq("titi")
          expect(motif_b.reload.instruction_for_rdv).to eq("titi")
        end
      end
    end

    describe "updating custom_cancel_warning_message" do
      let!(:motif_a) { create(:motif, organisation: organisation_a, custom_cancel_warning_message: "toto") }
      let!(:motif_b) { create(:motif, organisation: organisation_b, custom_cancel_warning_message: "tata") }

      it "works" do
        visit batch_edit_admin_territory_motifs_path(territory_id: territory.id, motif_ids: [motif_a.id, motif_b.id])

        within("#custom_cancel_warning_message_form") do
          fill_in "Message d’avertissement en cas d’annulation", with: "titi"
          click_on "Appliquer"
          expect(motif_a.reload.custom_cancel_warning_message).to eq("titi")
          expect(motif_b.reload.custom_cancel_warning_message).to eq("titi")
        end
      end
    end
  end

  describe "archiving" do
    let!(:organisation) { create(:organisation, territory: territory) }
    let!(:motif) { create(:motif, organisation: organisation) }

    before do
      agent.roles.create!(organisation: organisation, access_level: AgentRole::ACCESS_LEVEL_ADMIN)
    end

    it "works" do
      visit admin_territory_motifs_path(territory)
      expect(page).to have_content(motif.name)
      expect { click_on "Archiver" }.to change { motif.reload.archived? }.from(false).to(true)
      expect(page).to have_content("Le motif #{motif.name} a été archivé")
    end
  end

  describe "un-archiving" do
    let!(:organisation) { create(:organisation, territory: territory) }
    let!(:motif) { create(:motif, organisation: organisation).tap(&:archive!) }

    before do
      agent.roles.create!(organisation: organisation, access_level: AgentRole::ACCESS_LEVEL_ADMIN)
    end

    it "works" do
      visit admin_territory_motifs_path(territory, current_tab: "archived")
      expect(page).to have_content(motif.name)
      expect { click_on "Réactiver" }.to change { motif.reload.archived? }.from(true).to(false)
      expect(page).to have_content("Le motif #{motif.name} a été réactivé")
    end

    context "when an active duplicate exists" do
      before do
        duplicate = motif.dup
        duplicate.deleted_at = nil
        duplicate.save!
      end

      it "explains why the motif can't be un-archived" do
        visit admin_territory_motifs_path(territory, current_tab: "archived")
        expect { click_on "Réactiver" }.not_to change { motif.reload.archived? }.from(true)
        expect(page).to have_content("Nom est déjà utilisé : un motif du même type et du même service porte déjà ce nom dans cette organisation.")
      end
    end
  end

  describe "destroying a motif" do
    let!(:organisation) { create(:organisation, territory: territory) }
    let!(:motif) { create(:motif, organisation: organisation).tap(&:archive!) }

    before do
      agent.roles.create!(organisation: organisation, access_level: AgentRole::ACCESS_LEVEL_ADMIN)
    end

    context "when it was not used for any RDV" do
      it "removes it from the database" do
        motif.archive!

        visit admin_territory_motifs_path(territory, current_tab: "archived")
        expect { click_on "Supprimer" }.to change { Motif.exists?(motif.id) }.from(true).to(false)
        expect(page).to have_content("Le motif #{motif.name} a été supprimé")
      end
    end

    context "when it was used for some RDVs" do
      it "displays an error" do
        # On visite l'index avant de créer les RDVs pour faire en sorte que le bouton
        # "Supprimer" s'affiche, pour pouvoir cliquer dessus et obtenir l'erreur.
        visit admin_territory_motifs_path(territory, current_tab: "archived")
        create_list(:rdv, 2, organisation: motif.organisation, motif: motif)

        expect { click_on "Supprimer" }.not_to change { Motif.exists?(motif.id) }.from(true)
        expect(page).to have_content("Impossible de supprimer le motif : il est lié à 2 rendez-vous.")
      end
    end
  end
end
