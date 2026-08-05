RSpec.describe "Prise de RDV - motif réservable uniquement par les prescripteurs" do
  let(:now) { Time.zone.parse("2021-12-13 8:00") }
  let!(:territory) { create(:territory, departement_number: "92") }
  let!(:organisation) { create(:organisation, territory: territory) }

  let!(:service) { create(:service) }
  let!(:lieu) { create(:lieu, organisation: organisation) }
  let!(:motif) { create(:motif, bookable_by: :agents_and_prescripteurs, organisation: organisation, plage_ouvertures: [create(:plage_ouverture, lieu: lieu)]) }

  before { travel_to(now) }

  it "ne propose pas de créneaux" do
    visit root_path(departement: "92")
    expect(page).to have_content("Malheureusement, aucun créneau correspondant à votre recherche n'a été trouvé. Veuillez réessayer ultérieurement.")

    motif.update!(bookable_by: "everyone") # to make sure this spec isn't a false positive

    visit root_path(departement: "92")
    expect(page).not_to have_content("Malheureusement, aucun créneau correspondant à votre recherche n'a été trouvé. Veuillez réessayer ultérieurement.")
  end

  context "bookable_by=agents_and_prescripteurs_and_invited_users" do
    let!(:motif) { create(:motif, bookable_by: :agents_and_prescripteurs_and_invited_users, organisation: organisation, plage_ouvertures: [create(:plage_ouverture, lieu: lieu)]) }

    it "ne propose pas de créneaux" do
      visit root_path(departement: "92")
      expect(page).to have_content("Malheureusement, aucun créneau correspondant à votre recherche n'a été trouvé. Veuillez réessayer ultérieurement.")

      motif.update!(bookable_by: "everyone") # to make sure this spec isn't a false positive

      visit root_path(departement: "92")
      expect(page).not_to have_content("Malheureusement, aucun créneau correspondant à votre recherche n'a été trouvé. Veuillez réessayer ultérieurement.")
    end
  end
end
