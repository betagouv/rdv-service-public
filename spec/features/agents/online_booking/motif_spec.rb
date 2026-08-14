RSpec.describe "Réservation en ligne pour un motif en particulier" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
  let!(:motif) do
    create(:motif, organisation: organisation, bookable_by: :everyone, collectif: false)
  end

  before { login_as(agent, scope: :agent) }

  it "permet de modifier les options de réservation" do
    visit admin_organisation_online_booking_path(organisation)
    click_on motif.name

    expect(page).to have_content("Ce motif est ouvert à la réservation en ligne")

    click_on "Modifier", match: :first

    select "1 jour", from: "Délai minimum avant le RDV"
    select "6 heures", from: "Délai maximum avant le RDV"

    click_on "Enregistrer"

    expect(page).to have_content("Délai maximum de réservation doit être supérieur au délai de réservation minimum")

    select "2 jours", from: "Délai maximum avant le RDV"

    click_on "Enregistrer"

    expect(page).to have_content("Les options de réservation en ligne ont été mises à jour.")

    expect(page).to have_content("Les rendez-vous seront pris au moins 1 jour et au maximum 2 jours à l'avance.")
  end

  it "permet de modifier les consignes pour les usagers" do
    visit admin_organisation_online_booking_motif_path(organisation, motif)

    expect(page).to have_content "Pas d'instructions à accepter avant la prise de rendez-vous"
    expect(page).to have_content "Pas d'instructions à afficher après la prise de rendez-vous"

    visit edit_instructions_admin_organisation_online_booking_motif_path(organisation, motif)
    fill_in :motif_restriction_for_rdv, with: "Rendez-vous réservé aux usagers élibibles"
    fill_in :motif_instruction_for_rdv, with: "Pensez à prendre un justificatif de domicile"

    click_on "Enregistrer"
    expect(page).to have_content("Les consignes pour les usagers ont été mises à jour.")

    expect(page).to have_content "Rendez-vous réservé aux usagers élibibles"

    expect(page).to have_content "Pensez à prendre un justificatif de domicile"
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

  describe "sectorisation" do
    context "pour un espace qui n'utilise pas de sectorisation" do
      it "n'affiche pas les informations de sectorisation pour éviter de surcharger inutilement la page" do
        visit admin_organisation_online_booking_motif_path(organisation, motif)
        expect(page).not_to have_content("Sectorisation")
      end
    end

    context "pour un espace qui utilise la sectorisation" do
      before { create(:sector, territory: organisation.territory) }

      it "permet de modifier les options de sectorisation" do
        visit admin_organisation_online_booking_motif_path(organisation, motif)
        expect(page).to have_content("Sectorisation")
        expect(page).to have_content("Réservable par les usagers dans l'ensemble du département")
        expect(motif.reload.sectorisation_level).to eq("departement")

        visit edit_sectorisation_admin_organisation_online_booking_motif_path(organisation, motif)

        find("label", text: "Réservable par les usagers uniquement dans les secteurs attribués à l'organisation").click
        click_on "Enregistrer"

        expect(page).to have_content("Le niveau de sectorisation a été mis à jour.")

        expect(motif.reload.sectorisation_level).to eq("organisation")
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

  context "quand l'organisation est liée à RDV Insertion" do
    let!(:organisation) { create(:organisation, verticale: :rdv_insertion) }

    it "permet d'activer ou désactiver l'ouverture aux usagers invités" do
      visit admin_organisation_online_booking_motif_path(organisation, motif)
      click_on "Restreindre aux usagers invités"

      expect(page).to have_content("La réservation en ligne pour ce motif est maintenant ouverte uniquement aux usagers invités")
      expect(motif.reload).to have_attributes(bookable_by: "agents_and_prescripteurs_and_invited_users")

      click_on "Fermer à la réservation en ligne"

      expect(page).to have_content("Le motif a été fermé à la réservation en ligne")
      expect(motif.reload).to have_attributes(bookable_by: "agents")

      click_on "Ouvrir aux usagers invités"

      expect(page).to have_content("La réservation en ligne pour ce motif est maintenant ouverte uniquement aux usagers invités")
      expect(motif.reload).to have_attributes(bookable_by: "agents_and_prescripteurs_and_invited_users")

      click_on "Ouvrir à la réservation en ligne"

      expect(page).to have_content("Le motif a été ouvert à la réservation en ligne")
      expect(motif.reload).to have_attributes(bookable_by: "everyone")
    end
  end
end
