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
  end

  describe "Deleting a motif" do
    let!(:organisation) { create(:organisation, territory: territory) }
    let!(:motif) { create(:motif, organisation: organisation) }

    before do
      agent.roles.create!(organisation: organisation, access_level: AgentRole::ACCESS_LEVEL_ADMIN)
    end

    it "works" do
      visit admin_territory_motifs_path(territory)
      expect { click_on "Supprimer" }.to change { Motif.exists?(id: motif.id) }.from(true).to(false)
      expect(page).to have_content("Le motif a été supprimé")
    end
  end
end
