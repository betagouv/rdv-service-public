RSpec.describe "Prise de RDV pour un motif sans service" do
  let(:now) { Time.zone.parse("2021-12-13 8:00") }
  let!(:motif) { create(:motif, name: "Vaccination", organisation: organisation, service: nil, location_type: Motif.location_types[:visio]) }
  let!(:plage_ouverture) { create(:plage_ouverture, :weekdays, first_day: now + 1.month, motifs: [motif], organisation: organisation) }
  let(:organisation) { create(:organisation) }

  before { travel_to(now) }

  it "permet de prendre rendez-vous" do
    visit public_link_to_org_path(organisation_id: organisation.public_link_id)
    click_on "Vaccination"
    click_on "Prochaine disponibilité"
    first(:link, "08:00").click

    fill_in("Prénom", with: "Michel")
    fill_in("Nom", with: "Lapin")
    fill_in("Adresse email", with: "michel@lapin.fr")
    click_button("Recevoir un code de connexion")
    fill_in("Code à 6 chiffres", with: LoginCode.most_recent_usable_for(email: "michel@lapin.fr").code)
    click_on("Valider")

    expect(page).to have_content("Confirmez votre rendez-vous")

    click_on "Confirmer mon RDV"
    expect(page).to have_content "Votre rendez vous a été confirmé."
  end
end
