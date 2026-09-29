RSpec.describe "Prise de rendez-vous par un instructeur", js: true do
  include ActionView::Helpers::SanitizeHelper

  let(:oauth_application) { create(:oauth_application, name: "Démarches Simplifiées") }
  let!(:plage_ouverture) { create(:plage_ouverture, :weekdays, agent:, motifs: [motif, phone_motif], first_day: 2.weeks.ago) }
  let!(:user) do
    create(:user, latest_login_at: nil, organisations: [organisation],
                  email: "camille.dupont@exemple.fr", phone_number: nil,
                  first_name: "Camille", last_name: "Dupont")
  end
  let!(:motif) { create(:motif, organisation: organisation, location_type: :public_office, name: "Suivi de dossier en présentiel") }
  let!(:phone_motif) { create(:motif, organisation: organisation, location_type: :phone, name: "Suivi de dossier") }
  let!(:lieu) { create(:lieu, organisation:) }
  let(:organisation) { create(:organisation, name: "Préfecture de Police de Paris") }

  let!(:agent) do
    create(:agent, first_name: "Alex", last_name: "Emple",
                   email: "alex.emple@exemple.gouv.fr",
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
    doc = Autodoc.start_scenario("4) Prise de RDV avec invitation par un instructeur", self, accessibility_checks: false, category: "4) Intégration à Démarches Simplifiées")

    doc.start_section("Prise de rendez-vous par invitation")

    text = <<~TEXT
      <p>
        Je suis un instructeur qui utilise Démarches Simplifiées, et qui a déjà pris des rendez-vous avec l'intégration.
      </p>
      <p>
        J'ai déjà déclaré une plage d'ouverture pour mes motifs.
      </p>
    TEXT
    doc.add_text(sanitize(text))
    login_as(agent, scope: :agent)

    rdv_plan = create(:rdv_plan,
                      user: user,
                      rdv_agent: agent,
                      planning_agent: agent,
                      return_url: "https://demo.demarches-simplifiees.fr/callback/123",
                      oauth_application:)

    visit agents_rdv_plan_path(rdv_plan.id)

    Capybara.page.current_window.resize_to(1280, 700)

    doc.add_screenshot(page,
                       text: "Je choisis le motif sur place",
                       wait_for: "Suivi de dossier en présentiel")

    click_on "Suivi de dossier en présentiel"

    doc.add_screenshot(page,
                       text: "On m'indique qu'une invitation va être envoyée",
                       wait_for: "Nous allons envoyer un email à Camille DUPONT pour lui permettre de choisir un créneau.")

    click_on "Continuer"

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
