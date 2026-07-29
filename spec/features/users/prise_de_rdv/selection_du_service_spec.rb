RSpec.describe "prise de RDV - 2 motifs de services différents portent le même nom et location type" do
  let(:now) { Time.zone.parse("2021-12-13 8:00") }
  let!(:territory) { create(:territory, departement_number: "92") }
  let!(:organisation) { create(:organisation, territory: territory) }
  let!(:service) { create(:service) }
  let!(:other_service) { create(:service) }
  let!(:motif) do
    create(
      :motif, :by_phone, name: "Consultation", service: service, organisation: organisation, plage_ouvertures: [create(:plage_ouverture)]
    )
  end
  let!(:other_motif) do
    create(
      :motif, :by_phone, name: "Consultation", service: other_service, organisation: organisation, plage_ouvertures: [create(:plage_ouverture)]
    )
  end

  before { travel_to(now) }

  it "shows the service selection" do
    visit root_path(departement: "92")

    expect(page).to have_content("Sélectionnez le service puis le motif pour lequel vous voulez prendre un RDV")
    expect(page).to have_content(service.name)
    expect(page).to have_content(other_service.name)
  end
end
