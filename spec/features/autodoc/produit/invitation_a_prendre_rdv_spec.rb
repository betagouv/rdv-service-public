RSpec.describe "Invitation à prendre rendez-vous", js: true do
  let!(:motif) { create(:motif, name: "Suivi de dossier", organisation:) }
  let!(:plage_ouverture) do
    create(:plage_ouverture, :weekdays, motifs: [motif], lieu: lieu, organisation: organisation, first_day: now.next_week(:monday))
  end
  let(:organisation) { create(:organisation, name: "DREETS de l'Ile de France", verticale: :rdv_etat) }
  let!(:agent) { create(:agent, admin_role_in_organisations: [motif.organisation]) }
  let!(:user) { create(:user, organisations: [organisation]) }
  let(:lieu) { create(:lieu, organisation: organisation, name: "Bureau départemental", address: "21 rue des Ardennes, 75019 Paris") }
  let(:now) do
    Time.zone.local(2026, 8, 12, 14, 0, 0)
  end

  before do
    travel_to now
    login_as(agent, scope: :agent)
  end

  around { |example| perform_enqueued_jobs { example.run } }

  around do |example|
    previous_host = Capybara.app_host
    Capybara.app_host = "http://www.rdv-service-public-test.localhost:#{previous_host[/\d+/]}"
    example.run
    Capybara.app_host = previous_host
  end

  specify do
    doc = Autodoc.start_scenario("Invitation à prendre rendez-vous", self, category: "3) Produit", accessibility_checks: false)

    doc.start_section("Côté agent")

    doc.add_text("La fonctionnalité est cachée derrière un feature flag")
    agent.enable_feature!("rdv_invitations")

    visit calendar_admin_organisation_planning_plage_ouvertures_path(organisation.id)

    doc.add_screenshot(
      page,
      text: "J'ai une plage d'ouverture pour un motif qui n'est pas réservable en ligne",
      wait_for: "Planning de"
    )

    visit admin_organisation_user_path(organisation.id, user.id)

    doc.add_screenshot(
      page,
      text: "Je vais sur la page de l'usager, et je clique sur Trouver un rendez-vous",
      wait_for: "Informations générales"
    )

    click_on "Trouver un RDV pour l’usager"

    select("Suivi de dossier", from: "Motif")

    doc.add_screenshot(
      page,
      text: "Je fais une recherche de créneaux pour mon motif",
      wait_for: "Trouver un RDV"
    )

    click_on "Afficher les créneaux"

    doc.add_screenshot(
      page,
      text: "En dessous de la liste des créneaux, on me proposer de laisser l'usager choisir son créneau. Je clique sur ce lien",
      wait_for: "Vous pouvez aussi inviter l'usager à choisir son créneau."
    )

    click_on "inviter l'usager à choisir son créneau"

    doc.add_screenshot(
      page,
      text: "On me récapitule les infos. Je clique sur Envoyer l'invitation",
      wait_for: "Vous allez inviter"
    )

    click_on "Envoyer l'invitation"

    doc.add_screenshot(
      page,
      text: "J'ai un message de confirmation",
      wait_for: "Invitation envoyée"
    )

    logout

    doc.start_section("Côté usager")

    open_email(user.email)

    expect(current_email.subject).to eq "Vous êtes invité.e à prendre rendez-vous"

    doc.add_screenshot(current_email, text: "Je reçois un email d'invitation")

    current_email.click_on "Prendre rendez-vous"

    logout

    doc.add_screenshot(
      page,
      text: "Je choisis un créneau",
      wait_for: "8:00"
    )

    click_on "8:00", match: :first

    doc.add_screenshot(
      page,
      text: "Le rendez-vous est confirmé, on affiche le récapitulatif",
      wait_for: "confirmé"
    )
  end
end
