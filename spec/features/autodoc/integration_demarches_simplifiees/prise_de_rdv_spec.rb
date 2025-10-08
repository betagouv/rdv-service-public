RSpec.describe "Prise de rendez-vous par un instructeur", js: true do
  let(:oauth_application) do
    create(:oauth_application, name: "Démarches Simplifiées",
                               logo_base64: file_fixture("logo_demarches_simplifiees_base_64.txt").read)
  end
  let!(:user) do
    create(:user, :unregistered, organisations: [organisation],
                                 email: "camille.dupont@exemple.fr", phone_number: nil,
                                 first_name: "Camille", last_name: "Dupont") # créé par appel d'api par l'appli qui s'intègre avec nous
  end
  let!(:motif) { create(:motif, organisation: organisation, location_type: :public_office, name: "Suivi de dossier") }
  let!(:phone_motif) { create(:motif, organisation: organisation, location_type: :phone, name: "Suivi de dossier") }
  let!(:visio_motif) { create(:motif, organisation: organisation, location_type: :visio, name: "Suivi de dossier") }
  let!(:lieu) { create(:lieu, address: "8 Rue Froissart, 75003 Paris", name: "DDPP de Paris", organisation:) }
  let(:organisation) { create(:organisation, name: "Préfecture de Police de Paris") }

  let!(:oauth_token) { create(:access_token, resource_owner_id: agent.id, application: oauth_application) }
  let!(:agent) do
    create(:agent, first_name: "Alex", last_name: "Emple",
                   email: "alex.emple@exemple.gouv.fr", password: "RdvServicePublicTest1!",
                   basic_role_in_organisations: [organisation])
  end

  stub_env_for_proconnect

  around do |example|
    previous_host = Capybara.app_host
    Capybara.app_host = "http://www.rdv-mairie-test.localhost:#{previous_host[/\d+/]}"
    example.run
    Capybara.app_host = previous_host
  end

  specify do
    doc = Autodoc.start_scenario("Intégration à Démarches Simplifiées : 3) Prise de RDV par un instructeur", self)

    doc.start_section("Première prise de rendez-vous")

    doc.add_text <<~TEXT.html_safe # rubocop:disable Rails/OutputSafety
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

    visit oauth_authorization_path(
      client_id: oauth_application.uid,
      redirect_uri: oauth_application.redirect_uri.split("\n").first,
      response_type: :code, scope: :write, state: "fakestate"
    )

    doc.add_screenshot(page, text: "Je me ProConnecte", wait_for: "Vous devez vous connecter pour continuer")

    fill_in "Adresse email", with: agent.email
    fill_in "Mot de passe", with: agent.password
    click_on "Se connecter"

    doc.add_screenshot(page,
                       text: "On me demande de confirmer que j'accepte de connecter les deux applications. \
    (Il se peut que cette capture d'écran ne s'affiche pas dans l'autodoc, vous pouvez la récupérer depuis le parcours de connexion des admins.)")

    rdv_plan = create(:rdv_plan,
                      user: user,
                      rdv_agent: agent,
                      planning_agent: agent,
                      return_url: "https://demo.demarches-simplifiees.fr/callback/123",
                      oauth_application:)

    visit agents_rdv_plan_path(rdv_plan.id)

    Capybara.page.current_window.resize_to(1280, 1340)

    doc.add_screenshot(page,
                       text: "J'arrive sur mon agenda pour planifier un rendez-vous, je choisis un horaire.",
                       wait_for: "Convenez d'un horaire")

    find('.fc-timegrid-slot-lane[data-time="08:30:00"]').click # Clic sans l'agenda

    find("label", text: "Sur place").click

    Capybara.page.current_window.resize_to(1280, 880)

    doc.add_screenshot(page,
                       text: "Je choisis de faire le rendez-vous sur place.",
                       wait_for: "Comment souhaitez-vous faire le rendez-vous ?")

    click_on "Continuer"

    doc.add_screenshot(page,
                       text: "J'utilise le motif Suivi de dossier qui a été créé par défaut",
                       wait_for: "Motif")

    click_on "Continuer"

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
