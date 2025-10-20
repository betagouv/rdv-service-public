RSpec.describe "Configuration de RDV Service Public par un administrateur de DS", js: true do
  let(:application) { create(:oauth_application, name: "Démarches Simplifiées", default_service: create(:service)) }
  let!(:oauth_token) { create(:access_token, resource_owner_id: agent.id, application:) }
  let!(:agent) { create(:agent, :francis_factice) }

  after do
    Capybara.page.current_window.resize_to(1280, 720) # reset to default page size
  end

  specify do
    doc = Autodoc.start_scenario("Intégration à Démarches Simplifiées : 2) Configuration de RDV Service Public par un admin", self)

    login_as(agent, scope: :agent)
    visit configuration_admin_organisations_url(host: "http://www.rdv-mairie-test.localhost")

    doc.start_section("Ouverture de l'espace")

    Capybara.page.current_window.resize_to(1280, 600)

    doc.add_screenshot(page,
                       text: "Une première page me demande s'il existe déjà un espace dans RDV Service Public pour ma structure. Si ce n'est pas le cas, je clique sur Ouvrir un espace",
                       wait_for: "Bienvenue")

    click_on "Ouvrir un espace"

    fill_in("Nom de votre organisation", with: "Préfecture de Police de Paris")

    doc.add_screenshot(page,
                       text: "Je remplis ce formulaire pour ouvrir un espace pour ma structure, par exemple une préfecture",
                       wait_for: "Nouvel espace")

    click_on "Enregistrer"

    Capybara.page.current_window.resize_to(1280, 800)

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

    Capybara.page.current_window.resize_to(1280, 860)

    doc.add_screenshot(page,
                       text: "Cet agent ne fera que planifier des rendez-vous, donc je laisse le niveau de permission à Basique. J'indique sont adresse email et j'enregistre.",
                       wait_for: "Niveau de permissions")

    click_on "Enregistrer"

    Capybara.page.current_window.resize_to(1280, 600)

    doc.add_screenshot(page,
                       text: "Mon collègue reçoit un email lui permettant d'accéder à son compte. Je peux inviter d'autres collègues si nécessaire.",
                       wait_for: "a été invité à rejoindre votre organisation")

    doc.start_section("Inviter les agents qui vont gérer les rendez-vous (facultatif)")
    doc.add_text <<~TEXT
      Dans la plupart des cas, les rendez-vous seront assurés par des gens qui sont aussi instructeurs dans Démarches Simplifiées.
      Mais il peut arriver que ça ne soit pas le cas, et que l'agent qui assure le rendez-vous n'ai même pas de compte sur Démarches Simplifiées. Il suffit alors d'inviter ces agents dans RDV Service Public, comme on l'a déjà fait pour les agents.
    TEXT

    doc.start_section("Personaliser les motifs de rendez-vous (facultatif)")

    visit configuration_admin_organisations_url(host: "http://www.rdv-mairie-test.localhost")

    Capybara.page.current_window.resize_to(1280, 720)
    doc.add_screenshot(page,
                       text: "Des motifs de rendez-vous ont été créés par défaut à l'ouverture de mon compte. Je peux y accéder en cliquant sur la tuile Motifs depuis la configuration",
                       wait_for: "Configuration")

    click_on "Motifs"

    text = <<~TEXT
      Ces trois motifs me permettent de proposer des rendez-vous sur place, par téléphone ou par visio.
      Je peux archiver ceux qui ne me sont pas utiles, les renommer, ou en créer des nouveaux.
    TEXT
    doc.add_screenshot(page, text:, wait_for: "Durée par défaut")

    doc.start_section("Ajouter des lieux de rendez-vous (facultatif)")

    doc.add_text <<~TEXT
      Pour proposer des rendez-vous sur place pour rencontrer mes usagers en personne, je peux ajouter un lieu.
      A partir de la page de configuration, je clique sur la tuile "Lieux".
    TEXT

    visit admin_organisation_lieux_url(Organisation.last, host: "http://www.rdv-mairie-test.localhost")

    doc.add_screenshot(page,
                       text: "Je clique sur le bouton Ajouter un lieu",
                       wait_for: "Les lieux sont les endroits où sont réalisés les rendez-vous.")

    click_on "Ajouter un lieu", match: :first

    fill_in "Nom", with: "DDPP de Paris"
    fill_in "Adresse", with: "8 Rue Froissart, 75003 Paris"

    # Pour simuler l'autocomplete
    page.execute_script("document.querySelector('input#lieu_latitude').value = '48.583844'")
    page.execute_script("document.querySelector('input#lieu_longitude').value = 7.735253")

    doc.add_screenshot(page, text: "J'indique le nom et l'adresse de mon lieu")

    click_on "Enregistrer"

    doc.add_screenshot(page, text: "Je peux maintenant proposer des rendez-vous à ce lieu.", wait_for: "Le lieu a été ajouté.")
  end
end
