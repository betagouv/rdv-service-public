RSpec.describe "Réservation en ligne pour un motif en particulier" do
  let!(:organisation) { organisations(:default_org) }
  let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
  let!(:motif) do
    create(:motif, organisation: organisation, bookable_by: :everyone, collectif: false)
  end

  before { login_as(agent, scope: :agent) }

  it "permet de modifier les options de réservation" do
    visit admin_organisation_online_booking_path(organisation)
    click_on motif.name

    expect(page).to have_content("Ce motif est ouvert à la réservation en ligne")

    click_on "Modifier"

    select "1 jour", from: "Délai minimum avant le RDV"
    select "6 heures", from: "Délai maximum avant le RDV"

    click_on "Enregistrer"

    expect(page).to have_content("Délai maximum de réservation doit être supérieur au délai de réservation minimum")

    select "2 jours", from: "Délai maximum avant le RDV"

    click_on "Enregistrer"

    expect(page).to have_content("Les options de réservation en ligne ont été mises à jour.")

    expect(page).to have_content("Les rendez-vous seront pris au moins 1 jour à l'avance.")
  end

  context "quand il n'y a pas de disponibilités" do
    before { visit admin_organisation_online_booking_motif_path(organisation, motif) }

    context "pour un motif collectif" do
      let!(:motif) do
        create(:motif, organisation: organisation, bookable_by: :everyone, collectif: true)
      end

      it "incite à créer un nouveau rendez-vous collectif" do
        expect(page).to have_content("Vous devez planifier un nouveau rendez-vous pour permettre la réservation en ligne sur ce motif.")
        expect(page).to have_content("Planifier un rendez-vous collectif")
      end
    end

    context "pour un motif individuel" do
      it "incite à créer un nouveau rendez-vous collectif" do
        expect(page).to have_content("Attention, ce motif est ouvert à la réservation en ligne, mais il n’est pas encore accessible à vos usagers.")
        expect(page).to have_content("Ouvrir une plage d'ouverture")
      end
    end
  end

  it "permet d'ouvrir ou fermer la réservation en ligne pour ce motif" do
    # La réservation par les prescripteurs sera gérée dans un menu à part, pas depuis la réservation en ligne.
    visit admin_organisation_online_booking_motif_path(organisation, motif)
    click_on "Fermer à la réservation en ligne"

    expect(page).to have_content("Le motif a été fermé à la réservation en ligne")
    expect(motif.reload).to have_attributes(bookable_by: "agents")

    click_on "Ouvrir à la réservation en ligne"

    expect(page).to have_content("Le motif a été ouvert à la réservation en ligne")
    expect(motif.reload).to have_attributes(bookable_by: "everyone")
  end
end
