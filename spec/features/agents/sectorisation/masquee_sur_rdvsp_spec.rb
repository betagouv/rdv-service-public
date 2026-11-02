RSpec.describe "Sectorisation masquée sur RDV Service Public", type: :feature do
  let!(:territory) { create(:territory) }
  let!(:organisation) { create(:organisation, territory:) }
  let!(:agent) { create(:agent, role_in_territories: [territory], admin_role_in_organisations: [organisation]) }
  let!(:motif) { create(:motif, organisation:) }
  let!(:sector) { create(:sector, territory:) }

  before { login_as(agent, scope: :agent) }

  context "sur RDV Service Public, où l'usager ne saisit pas son adresse" do
    it "n'affiche pas la tuile Sectorisation sur la page territoire" do
      visit admin_territory_url(territory, host: "www.rdv-service-public-test.localhost")
      expect(page).not_to have_link("Sectorisation")
    end

    it "n'affiche pas le bloc Sectorisation sur la fiche motif en réservation en ligne" do
      visit admin_organisation_online_booking_motif_url(organisation, motif, host: "www.rdv-service-public-test.localhost")
      expect(page).not_to have_content("Sectorisation")
    end
  end

  context "sur RDV Solidarités, où l'usager saisit son adresse" do
    it "affiche la tuile Sectorisation sur la page territoire" do
      visit admin_territory_path(territory)
      expect(page).to have_link("Sectorisation")
    end

    it "affiche le bloc Sectorisation sur la fiche motif en réservation en ligne" do
      visit admin_organisation_online_booking_motif_path(organisation, motif)
      expect(page).to have_content("Sectorisation")
    end
  end
end
