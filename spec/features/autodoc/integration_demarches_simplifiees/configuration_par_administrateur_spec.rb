RSpec.describe "Configuration de RDV Service Public par un administrateur de DS après avoir connecté son compte", js: true do
  let(:application) { create(:oauth_application, name: "Démarches Simplifiées", default_service: create(:service)) }
  let!(:oauth_token) { create(:access_token, resource_owner_id: agent.id, application:) }
  let!(:agent) do
    create(:agent, email: "francis.factice@exemple.gouv.fr", password: "RdvServicePublicTest1!", first_name: "Francis", last_name: "Factice")
  end

  around do |example|
    previous_host = Capybara.app_host
    Capybara.app_host = "http://www.rdv-mairie-test.localhost:#{previous_host[/\d+/]}"
    example.run
    Capybara.app_host = previous_host
  end

  specify do
    doc = Autodoc.start_scenario("Configuration de RDV Service Public par un administrateur de DS après avoir connecté son compte", self)

    login_as(agent, scope: :agent)
    visit("/admin/organisations/configuration")

    doc.start_section("Ouverture de l'espace")

    doc.add_screenshot(page,
                       text: "une première page me demande s'il existe déjà un espace dans RDV Service Public pour ma structure. Si ce n'est pas le cas, je clique sur Ouvrir un espace",
                       wait_for: "Bienvenue")

    click_on "Ouvrir un espace"

    fill_in("Nom du territoire", with: "Préfecture de Police de Paris")
    fill_in("Nom de votre organisation", with: "Préfecture de Police de Paris")

    doc.add_screenshot(page,
                       text: "Je remplis ce formulaire pour ouvrir un espace pour ma structure, par exemple une préfecture",
                       wait_for: "Nouvel espace")

    click_on "Enregistrer"

    doc.add_screenshot(page,
                       text: "J'arrive sur la page de configuration de RDV Service Public",
                       wait_for: "Configuration")

    doc.start_section("Inviter les instructeurs qui vont planifier les rendez-vous")
    doc.add_text("J'ai trois instructeurs qui vont planifier les rendez-vous, je vais les inviter à utiliser RDV Service Public.")
    doc.add_text("J'ouvre le menu Agents de la configuration")
    click_on "Agents"

    doc.add_screenshot(page,
                       text: "Je clique sur Ajouter un agent",
                       wait_for: "Ajouter un agent")

    click_on "Ajouter un agent", match: :first

    fill_in "Email", with: "alex.emple@exemple.gouv.fr"

    doc.add_screenshot(page,
                       text: "Ce agent ne fera que planifier des rendez-vous, donc je laisse le niveau de permission à Basique. J'indique sont adresse email et j'enregistre.",
                       wait_for: "Niveau de permissions")

    click_on "Enregistrer"

    doc.add_screenshot(page,
                       text: "Mon collègue reçoit un email lui permettant d'accéder à son compte. Je peux inviter d'autres collègues si nécessaire.",
                       wait_for: "a été invité à rejoindre votre organisation")
  end
end
