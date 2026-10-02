RSpec.describe "Prise de RDV usager pour un motif à domicile" do
  let!(:territory) { create(:territory, enable_address_field: false) }
  let!(:organisation) { create(:organisation, territory:) }
  let!(:user) { create(:user, address: nil) }
  let!(:motif) { create(:motif, :at_home, organisation:) }
  let!(:lieu) { create(:lieu, organisation:) }
  let!(:plage_ouverture) do
    create(:plage_ouverture, :weekdays, first_day: Date.parse("2024-11-04"), motifs: [motif], lieu:, organisation:, start_time: Tod::TimeOfDay.new(8), end_time: Tod::TimeOfDay.new(12))
  end

  before { travel_to Date.parse("2024-11-03").in_time_zone + 8.hours }
  before { login_as(user, scope: :user) }

  it "confirme le RDV et enregistre l’adresse" do
    visit public_link_to_motif_path(public_link_id: motif.public_link_id)
    click_link "08:00", match: :first
    expect(page).to have_content("Vos informations")
    # on tente de soumettre sans renseigner d'adresse,
    # c'est possible car le HTML attr required n'est pas respecté dans les specs e2e sans JS
    click_button("Confirmer mon RDV")
    expect(page).to have_content("L’adresse est obligatoire car le RDV aura lieu à domicile")
    expect(Rdv.count).to eq(0)
    # on tente de soumettre une adresse blank
    fill_in "Adresse", with: "  "
    click_button("Confirmer mon RDV")
    expect(page).to have_content("L’adresse est obligatoire car le RDV aura lieu à domicile")
    expect(Rdv.count).to eq(0)
    # puis on renseigne une adresse
    fill_in "Adresse", with: "20 avenue de Ségur, Paris, 75007"
    click_button("Confirmer mon RDV")
    expect(page).to have_content("Votre rendez vous a été confirmé")
    expect(user.reload.address).to eq("20 avenue de Ségur, Paris, 75007")
  end
end
