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
    let!(:organisation) { create(:organisation, territory: territory) }
    let!(:service_pmi) { create(:service, :pmi).tap { territory << _1 } }
    let!(:service_social) { create(:service, :social).tap { territory << _1 } }
    let!(:motif_a) { create(:motif, organisation: organisation, service: service_pmi, location_type: :public_office) }
    let!(:motif_b) { create(:motif, organisation: organisation, service: service_pmi, location_type: :phone) }
    let!(:motif_c) { create(:motif, organisation: organisation, service: service_pmi, location_type: :home) }

    before do
      agent.roles.create!(organisation: organisation, access_level: AgentRole::ACCESS_LEVEL_ADMIN)
    end

    it "works" do
      visit admin_territory_motifs_path(territory)
      find("[type=checkbox][value=#{motif_a.id}]").check
      find("[type=checkbox][value=#{motif_c.id}]").check
      click_on "Modifier les motifs"

      expect(page).to     have_content("Modifier les motifs")
      expect(page).to     have_content(motif_a.name)
      expect(page).not_to have_content(motif_b.name)
      expect(page).to     have_content(motif_c.name)

      within("#name_form") do
        fill_in "Nom du motif", with: "Nom corrigé"
        click_on "Appliquer"
        expect([motif_a, motif_c].map { _1.reload.name }).to eq(["Nom corrigé", "Nom corrigé"])
      end

      within("#service_form") do
        select service_social.name, from: "Service"
        click_on "Appliquer"
        expect([motif_a, motif_c].map { _1.reload.service }).to eq([service_social, service_social])
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
