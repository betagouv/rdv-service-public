RSpec.describe "Non-admin agents can view online booking without editing it" do
  let!(:organisation) { create(:organisation) }
  let!(:service) { create(:service) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation], services: [service]) }
  let!(:motif) { create(:motif, organisation: organisation, service: service, bookable_by: :everyone, collectif: false) }
  let!(:other_service_motif) { create(:motif, organisation: organisation, service: create(:service), bookable_by: :everyone, collectif: false) }

  before { login_as(agent, scope: :agent) }

  it "affiche le menu Réservation en ligne" do
    visit admin_organisation_planning_agenda_path(organisation)
    expect(page).to have_link("Réservation en ligne", href: admin_organisation_online_booking_path(organisation))
  end

  it "permet de consulter les liens de réservation sans pouvoir modifier les paramètres" do
    visit admin_organisation_online_booking_path(organisation)

    expect(page).to have_content("Lien de réservation")
    expect(page).to have_content(motif.name)
    expect(page).not_to have_content(other_service_motif.name)
    expect(page).not_to have_link("Modifier")

    click_on motif.name

    expect(page).to have_content("Lien de réservation direct")
    expect(page).not_to have_link("Modifier")
    expect(page).not_to have_button("Fermer à la réservation en ligne")
  end

  it "affiche un message quand aucun motif n'est encore ouvert, sans proposer le formulaire de configuration" do
    motif.update!(bookable_by: :agents)
    other_service_motif.update!(bookable_by: :agents)

    visit admin_organisation_online_booking_path(organisation)

    expect(page).to have_content("La réservation en ligne n'est pas encore configurée")
    expect(page).not_to have_content("Pour quels motifs souhaitez-vous ouvrir la prise de rendez-vous en ligne ?")
  end

  it "refuse l'accès direct aux pages de modification" do
    visit edit_admin_organisation_online_booking_path(organisation)
    expect(page).not_to have_content("Pour quels motifs souhaitez-vous ouvrir la prise de rendez-vous en ligne ?")

    visit edit_user_type_admin_organisation_online_booking_path(organisation)
    expect(page).not_to have_content("Modes d'authentification")

    visit edit_admin_organisation_online_booking_motif_path(organisation, motif)
    expect(page).not_to have_content("Options de réservation")
  end
end
