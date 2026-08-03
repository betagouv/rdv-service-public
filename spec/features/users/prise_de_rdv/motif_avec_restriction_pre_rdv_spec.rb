RSpec.describe "Prise de RDV pour un motif avec restriction pré-RDV" do
  let!(:territory) { create(:territory, departement_number: "92") }
  let!(:organisation) { create(:organisation, territory:) }
  let!(:lieu) { create(:lieu, organisation:) }
  let!(:motif) { create(:motif, organisation:, restriction_for_rdv: "Merci d'apporter les documents nécessaires") }
  let!(:plage_ouverture) { create(:plage_ouverture, :weekdays, motifs: [motif], lieu:, organisation:) }

  it "oblige à accepter la restriction avant de choisir un créneau", js: true do
    visit root_path(departement: "92")
    click_link(motif.name)

    click_on(lieu.name)
    expect(page).to have_content("Merci d'apporter les documents nécessaires")
    click_on "Annuler"
    click_on(lieu.name)
    expect(page).to have_content("Merci d'apporter les documents nécessaires")
    click_on "Accepter"

    expect(page).to have_content("Sélectionnez un créneau")
  end
end
