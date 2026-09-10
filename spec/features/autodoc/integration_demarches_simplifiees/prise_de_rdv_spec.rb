RSpec.describe "Prise de rendez-vous par un instructeur", js: true do
  include ActionView::Helpers::SanitizeHelper

  let(:oauth_application) do
    create(:oauth_application, name: "Démarches Simplifiées",
                               logo_base64: file_fixture("logo_demarches_simplifiees_base_64.txt").read)
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
                   basic_role_in_organisations: [organisation])
  end

  around do |example|
    previous_host = Capybara.app_host
    Capybara.app_host = "http://www.rdv-service-public-test.localhost:#{previous_host[/\d+/]}"
    example.run
    Capybara.app_host = previous_host
  end

  stub_env_for_proconnect

  specify do
    doc = Autodoc.start_scenario("3) Prise de RDV par un instructeur", self, accessibility_checks: false, category: "4) Intégration à Démarches Simplifiées")

    doc.start_section("Première prise de rendez-vous")

    text = <<~TEXT
      <p>
        Je suis un instructeur qui utilise Démarches Simplifiées.
      </p>
      <p>
        Je n'ai jamais utilisé RDV Service Public, mais j'ai vu que l'administrateur m'a invité à rejoindre un espace RDV Service Public.
        J'ai l'habitude d'utiliser ProConnect.
      </p>
      <p>
        Je suis en train d'instruire un dossier, et je vois que j'ai la possibilité de prendre un rendez-vous. Je clique dessus depuis Démarches Simplifiées, et j'arrive sur ces écrans de RDV Service Public.
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
                       text: "Je choisis l'horaire",
                       wait_for: "Convenez d'un horaire")

    page.driver.with_playwright_page do |pw|
      slot = pw.locator('[data-time="08:30:00"]').last
      box = slot.bounding_box
      pw.mouse.click(box["x"] + (box["width"] / 2), box["y"] + (box["height"] / 2))
    end
    sleep 0.1

    doc.add_screenshot(page,
                       text: "Je choisis le lieu",
                       wait_for: "Suivi de dossier en présentiel")

    click_on "DDPP de Paris"

    Capybara.page.current_window.resize_to(1280, 900)

    doc.add_screenshot(page,
                       text: "Je vérifie que j'ai les bonnes coordonnées, et je valide",
                       wait_for: "Coordonnées de ")

    click_on "Confirmer le rendez-vous"

    Capybara.page.current_window.resize_to(1280, 720)
    doc.add_screenshot(page,
                       text: "J'ai un récapitulatif du rendez-vous, et je peux retourner sur Démarches Simplifiées",
                       wait_for: "Rendez-vous confirmé")

    doc.start_section("Deuxième prise de rendez-vous")

    doc.add_text("Pour les rendez-vous suivants, on ne repasse plus par l'étape de validation des permissions, mais on arrive directement sur le choix de l'horaire (si on est déjà connecté).")
  end
end
