RSpec.describe "Prise de rendez-vous depuis le lien d'un motif" do
  let(:organisation) { create(:organisation) }
  let!(:motif) do
    create(:motif, bookable_by: :everyone, organisation:)
  end
  let(:lieu) { create(:lieu, organisation:) }

  before do
    travel_to(Time.zone.parse("2022-09-12 15:00:00"))
    create(:plage_ouverture, motifs: [motif], lieu:)
  end

  it "permet une prise de rendez-vous mais ne permet pas de changer de motif" do
    visit public_link_to_motif_path(public_link_id: motif.public_link_id, motif_slug: motif.slug)

    expect(page).to have_content(motif.name)
    expect(page).not_to have_content("Modifier")

    click_on(lieu.name)

    # On a un lien de modification pour le lieu
    expect(page).to have_content("Modifier", count: 1)

    click_on("08:00")

    # On a un lien de modification pour le lieu et un pour l'horaire
    expect(page).to have_content("Modifier", count: 2)

    fill_in "Prénom", with: "Francis"
    fill_in "Nom", with: "Factice"
    fill_in "Adresse email", with: "francis@factice.org"
    click_on "Recevoir un code de connexion"

    expect(page).to have_content("Saisie du code de connexion")

    # Ici aussi on a un lien de modification pour le lieu et un pour l'horaire, mais pas de lien pour changer le motif
    expect(page).to have_content("Modifier", count: 2)

    fill_in "Code à 6 chiffres", with: LoginCode.last.code
    click_on "Valider"

    expect(page).to have_content("Confirmez votre rendez-vous")

    # Ici aussi on a un lien de modification pour le lieu et un pour l'horaire, mais pas de lien pour changer le motif
    expect(page).to have_content("Modifier", count: 2)

    # On change le lieu
    click_on "Modifier", match: :first

    # On n'affiche toujours pas de lien pour changer le motif
    expect(page).not_to have_content("Modifier")
  end
end
