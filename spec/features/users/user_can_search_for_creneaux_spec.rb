# frozen_string_literal: true

describe "User can search for creneaux" do
  let(:now) { Time.zone.parse("2021-12-13 8:00") }

  let!(:territory92) { create(:territory, departement_number: "92") }
  let!(:organisation) { create(:organisation, territory: territory92) }
  let!(:lieu) { create(:lieu, organisation: organisation) }

  before { travel_to(now) }

  context "when the next creneau is after the max booking delay" do
    let!(:motif) { create(:motif, name: "Vaccination", reservable_online: true, organisation: organisation, max_booking_delay: 7.days) }
    let!(:plage_ouverture) { create(:plage_ouverture, :daily, first_day: now + 8.days, motifs: [motif], lieu: lieu, organisation: organisation) }

    it "doesn't show a next availability date", js: true do
      visit root_path
      fill_in("search_where", with: "79 Rue de Plaisance, 92250 La Garenne-Colombes")

      # Fake autocomplete
      page.execute_script("document.querySelector('#search_departement').value = '92'")
      page.execute_script("document.querySelector('#search_submit').disabled = false")

      click_button("Rechercher")

      select(motif.service.name, from: "search_service")
      click_button("Choisir ce service")

      select(motif.name, from: "search_motif_name_with_location_type")
      click_button("Choisir ce motif")

      expect(page).to have_content("Aucune disponibilité")
    end
  end
end
