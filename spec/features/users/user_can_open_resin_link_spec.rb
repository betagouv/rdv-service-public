# frozen_string_literal: true

# Ce test de non-régression a été ajouté pour s'assurer que le
# lien public que nous avons fourni à Rés'In est toujours fonctionnel.
RSpec.describe "Rés'In specific public link" do
  before do
    travel_to(Time.zone.parse("2023-01-30 17:00"))
  end

  let!(:cnfs_territory) { create(:territory, departement_number: "CN") }
  let!(:cnfs_service) { create(:service, :conseiller_numerique) }
  let!(:orga_cnfs_lyon_a) { create(:organisation, territory: cnfs_territory, external_id: "123") }
  let!(:orga_cnfs_lyon_b) { create(:organisation, territory: cnfs_territory, external_id: "456") }

  let!(:motif_a) { create(:motif, :sectorisation_level_departement, service: cnfs_service, organisation: orga_cnfs_lyon_a, name: "Accompagnement individuel", location_type: :public_office) }
  let!(:motif_b) { create(:motif, :sectorisation_level_departement, service: cnfs_service, organisation: orga_cnfs_lyon_b, name: "Accompagnement individuel", location_type: :public_office) }

  let!(:lieu_a) { create(:lieu, name: "Antenne Voltaire Lyon", organisation: orga_cnfs_lyon_a) }
  let!(:lieu_b) { create(:lieu, name: "Maison de la Métropole de Lyon", organisation: orga_cnfs_lyon_b) }

  let!(:plage_ouverture_a) { create(:plage_ouverture, motifs: [motif_a], lieu: lieu_a) }
  let!(:plage_ouverture_b) { create(:plage_ouverture, motifs: [motif_b], lieu: lieu_b) }

  it "allows user to book a RDV" do
    visit "/resin/123,456"
    expect(page).to have_content("Accompagnement individuel (Sur place)")
    expect(page).to have_content("2 lieux sont disponibles")
    expect(page).to have_content(motif_a.name)
    expect(page).to have_content(motif_b.name)

    click_on "Prochaine disponibilité lemardi 07 février 2023 à 08h00"
    click_on "08:00"
    expect(page).to have_content("Vous devez vous connecter ou vous inscrire pour continuer")
  end

  context 'when a motif is not named "Accompagnement individuel"' do
    before do
      motif_b.update!(name: "Accompagnement individuel 2")
    end

    it "is not shown" do
      visit "/resin/123,456"
      expect(page).to have_content(motif_a.name)
      expect(page).not_to have_content(motif_b.name)
    end
  end
end
