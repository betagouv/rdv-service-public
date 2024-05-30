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

    it "shows buttons only if motif is in agent's admin orgs" do
      agent.roles.create!(organisation: org_arques, access_level: AgentRole::ACCESS_LEVEL_ADMIN)
      visit admin_territory_motifs_path(territory)
      expect(page.body).to include(%(href="/admin/organisations/#{org_arques.id}/motifs))
      expect(page.body).not_to include(%(href="/admin/organisations/#{org_bapaume.id}/motifs))
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
