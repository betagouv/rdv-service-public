RSpec.describe "Prise de rendez-vous par un instructeur", js: true do
  include ActionView::Helpers::SanitizeHelper

  let(:oauth_application) do
    create(:oauth_application, name: "Démarches Simplifiées",
                               logo_base64: file_fixture("logo_demarches_simplifiees_base_64.txt").read)
  end
  let!(:plage_ouverture) do
    create(:plage_ouverture, :weekdays, agent:, motifs: [motif, phone_motif, visio_motif])
  end
  let!(:user) do
    create(:user, latest_login_at: nil, organisations: [organisation],
                  email: "camille.dupont@exemple.fr", phone_number: nil,
                  first_name: "Camille", last_name: "Dupont") # créé par appel d'api par l'appli qui s'intègre avec nous
  end
  let!(:motif) { create(:motif, organisation: organisation, location_type: :public_office, name: "Suivi de dossier en présentiel") }
  let!(:phone_motif) { create(:motif, organisation: organisation, location_type: :phone, name: "Suivi de dossier") }
  let!(:visio_motif) { create(:motif, organisation: organisation, location_type: :visio, name: "Suivi de dossier") }
  let!(:lieu) { create(:lieu, address: "8 Rue Froissart, 75003 Paris", name: "DDPP de Paris", organisation:) }
  let!(:other_lieu) { create(:lieu, address: "30 rue de la République, 94000 Nogent-sur-Marne", name: "DDPP du Val de Marne", organisation:) }
  let(:organisation) { create(:organisation, name: "Préfecture de Police de Paris") }

  let!(:agent) do
    create(:agent, first_name: "Alex", last_name: "Emple",
                   email: "alex.emple@exemple.gouv.fr", password: "RdvServicePublicTest1!",
                   admin_role_in_organisations: [organisation])
  end

  before { agent.enable_feature!("rdv_invitations") }

  around do |example|
    previous_host = Capybara.app_host
    Capybara.app_host = "http://www.rdv-service-public-test.localhost:#{previous_host[/\d+/]}"
    example.run
    Capybara.app_host = previous_host
  end

  stub_env_for_proconnect

  specify do
    doc = Autodoc.start_scenario("3) Prise de RDV par un instructeur", self, accessibility_checks: false, category: "4) Intégration à Démarches Simplifiées")

    doc.start_section("Prise de rendez-vous par invitation")

    text = <<~TEXT
      <p>
        Je suis un instructeur qui utilise Démarches Simplifiées.
      </p>
      <p>
        J'ai déjà déclaré une plage d'ouverture pour mes motifs.
      </p>
    TEXT
    doc.add_text(sanitize(text))
    login_as(agent, scope: :agent)

    visit oauth_authorization_path(
      client_id: oauth_application.uid,
      redirect_uri: oauth_application.redirect_uri.split("\n").first,
      response_type: :code, scope: :write, state: "fakestate"
    )

    # Si je ne suis pas connecté, je me fais rediriger vers le /authorize de ProConnect pour le silent login
    # Pour simplifier cette spec, on s'est connecté au préalable

    doc.add_screenshot(page,
                       text: "On me demande de confirmer que j'accepte de connecter les deux applications.",
                       wait_for: "vous allez permettre à Démarches Simplifiées")

    rdv_plan = create(:rdv_plan,
                      user: user,
                      rdv_agent: agent,
                      planning_agent: agent,
                      return_url: "https://demo.demarches-simplifiees.fr/callback/123",
                      oauth_application:)

    visit agents_rdv_plan_path(rdv_plan.id)

    Capybara.page.current_window.resize_to(1280, 1300)

    doc.add_screenshot(page,
                       text: "Je choisis le motif sur place",
                       wait_for: "Suivi de dossier en présentiel")

    click_on "Suivi de dossier en présentiel"

    doc.add_screenshot(page,
                       text: "On m'indique qu'une invitation va être envoyée",
                       wait_for: "Nous allons envoyer un email à Camille DUPONT pour lui permettre de choisir un créneau.")

    click_on "Continuer"

    Capybara.page.current_window.resize_to(1280, 900)

    doc.add_screenshot(page,
                       text: "Je vérifie que j'ai les bonnes coordonnées, et je valide",
                       wait_for: "Coordonnées de ")

    click_on "Envoyer l'invitation"

    Capybara.page.current_window.resize_to(1280, 720)
    doc.add_screenshot(page,
                       text: "J'ai un récapitulatif du rendez-vous, et je peux retourner sur Démarches Simplifiées",
                       wait_for: "Invitation envoyée")
  end
end
