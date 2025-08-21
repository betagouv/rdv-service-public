RSpec.describe "Configuration initiale", js: true do
  let(:agent) do
    create(:agent, admin_role_in_organisations: [organisation],
                   first_name: "Francis",
                   last_name: "Factice",
                   email: "francis.factice@demo-rdv-service-public.gouv.fr")
  end
  let(:organisation) { create(:organisation, name: "Equipe produit de Mon Permis de Construire") }

  before do
    login_as(agent, scope: :agent)
  end

  specify do
    doc = Autodoc.start_scenario("Incitation à la création de motifs et de lieux", self)

    doc.start_section("Contexte")

    doc.add_text(<<~TEXT
      <p>
        Quand une nouvelle organisation est créée, elle n'a pas encore de motifs. On veut permettre à l'agent d'explorer les différentes pages, mais l'inciter à créer un premier motif.
      </p>
    TEXT
      .html_safe) # rubocop:disable Rails/OutputSafety

    doc.start_section("Redirections vers la création de motif")

    doc.add_text("Voici ce qui s'affiche sur les différentes pages qui nécessitent un motif")

    visit new_admin_organisation_rdv_wizard_step_url(organisation, host: "http://www.rdv-mairie-test.localhost", starts_at: Time.zone.now, agent_ids: [agent.id])

    doc.add_screenshot(page,
                       text: "Prise de rendez-vous depuis le calendrier",
                       wait_for: "Nouveau RDV")

    expect(page).to have_content("Pour prendre un rendez-vous, vous devez d'abord créer un motif.")
    expect(page).not_to have_content("Vue calendrier")

    visit admin_organisation_creneaux_search_url(organisation, host: "http://www.rdv-mairie-test.localhost")

    doc.add_screenshot(page,
                       text: "Recherche de créneaux",
                       wait_for: "Trouver un RDV")

    expect(page).to have_content("Pour prendre un rendez-vous, vous devez d'abord créer un motif.")

    visit admin_organisation_rdvs_collectifs_url(organisation, host: "http://www.rdv-mairie-test.localhost", agent_id: agent.id)

    doc.add_screenshot(page,
                       text: "Liste des RDV collectifs",
                       wait_for: "Pour créer un RDV collectif")

    visit admin_organisation_planning_plage_ouvertures_url(organisation, host: "http://www.rdv-mairie-test.localhost", agent_id: agent.id)

    doc.add_screenshot(page,
                       text: "Liste des plages d'ouverture",
                       wait_for: "Vous n'avez pas encore créé de plage d'ouverture.")

    expect(page).to have_content("Pour créer une plage d'ouverture, vous devez d'abord créer un motif")

    visit admin_organisation_online_booking_url(organisation, host: "http://www.rdv-mairie-test.localhost")

    scroll_to(find(".fr-callout"))

    doc.add_screenshot(page,
                       text: "Réservation en ligne",
                       wait_for: "Permettez à vos usagers de prendre rendez-vous en ligne")

    expect(page).to have_content("Pour ouvrir la réservation en ligne, vous devez d'abord créer un motif de rendez-vous")

    doc.start_section("Configuration")

    visit admin_organisation_configuration_url(organisation, host: "http://www.rdv-mairie-test.localhost")

    doc.add_screenshot(page,
                       text: "On affiche un badge pour inciter à la création du premier motif",
                       wait_for: "À RENSEIGNER")

    click_on "Motifs de rendez-vous"

    doc.add_screenshot(page,
                       text: "",
                       wait_for: "Vous n'avez pas encore créé de motif.")

    click_on "Créer un motif", match: :first

    fill_in "Nom du motif", with: "Entretien utilisateur"

    doc.add_screenshot(page, text: "On crée un motif sur place")

    click_on "Créer le motif"

    doc.add_screenshot(page,
                       text: "Le message de confirmation m'incite à créer un lieu parce que le motif est sur place",
                       wait_for: "vous pouvez maintenant ajouter un lieu")

    visit admin_organisation_configuration_url(organisation, host: "http://www.rdv-mairie-test.localhost")

    doc.add_screenshot(page,
                       text: "La page de configuration m'incite maintenant à créer un lieu",
                       wait_for: "Aucun lieu")

    click_on "Lieux"

    doc.add_screenshot(page, wait_for: "Les lieux sont les endroits où sont réalisés les rendez-vous.")
  end
end
