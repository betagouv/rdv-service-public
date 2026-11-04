RSpec.describe "Prise de RDV pour un motif en visioconférence" do
  let!(:territory) { create(:territory, departement_number: "92") }
  let!(:organisation) { create(:organisation, :with_contact, territory:) }
  let!(:motif) { create(:motif, organisation:, location_type: Motif.location_types[:visio]) }
  let!(:plage_ouverture) { create(:plage_ouverture, :weekdays, lieu: nil, motifs: [motif], organisation:) }

  it "affiche la mention RDV par visioconférence avant et après la confirmation", js: true do
    visit root_path(departement: "92")
    click_link(motif.name)

    find(".fr-card__title", text: /#{organisation.name}/).ancestor(".fr-card__body").find("a").click

    first(:link, "08:00").click
    expect(page).to have_content("RDV par visioconférence")

    fill_in("Prénom", with: "Michel")
    fill_in("Nom", with: "Lapin")
    fill_in("Adresse email", with: "michel@lapin.fr")
    click_button("Recevoir un code de connexion")
    fill_in("Code à 6 chiffres", with: LoginCode.most_recent_usable_for(email: "michel@lapin.fr").code)
    click_on("Valider")

    click_button("Confirmer mon RDV")

    expect(page).to have_content("Votre RDV")
    expect(page).to have_content("RDV par visioconférence")
  end
end
