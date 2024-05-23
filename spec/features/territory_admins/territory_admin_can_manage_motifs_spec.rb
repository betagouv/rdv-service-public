RSpec.describe "territory admin can manage motifs", type: :feature do
  # # Le territoire doit avoir au moins un agent admin de territoire restant
  # let!(:territory) { create(:territory).tap { |t| t.roles.create!(agent: create(:agent)) } }
  let!(:territory) { create(:territory) }
  let!(:org_arques) { create(:organisation, name: "Arques", territory: territory) }
  let!(:org_bapaume) { create(:organisation, name: "Bapaume", territory: territory) }
  let!(:agent) { create(:agent, role_in_territories: [territory]) }

  before do
    login_as(agent, scope: :agent)
  end

  describe "Listing motifs" do
    let!(:motif_consultation_prenatale) { create(:motif, name: "Consultation prénatale", organisation: org_arques) }
    let!(:motif_suivi_apres_naissance) { create(:motif, name: "Suivi après naissance", organisation: org_bapaume) }

    it "works" do
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
  end
end
