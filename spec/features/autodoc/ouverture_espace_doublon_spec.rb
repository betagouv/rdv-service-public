# Les captures d'écran des emails dans autodoc causent des erreurs JS à cause d'images qui ne chargent pas correctement
# donc on désactive cette vérification pour ces specs
RSpec.describe "Ouverture d'un espace", ignore_js_errors: true, js: true do
  let!(:agent) { create(:agent, first_name: "Francis", last_name: "Factice", password: "c0rrecThorse!", email: "francis.factice@beta.gouv.fr") }
  let!(:agent_with_similar_email) { create(:agent, email: "alex.emple@beta.gouv.fr", admin_role_in_organisations: [create(:organisation)]) }

  around { |example| perform_enqueued_jobs { example.run } }

  specify do
    doc = Autodoc.start_scenario("3) Détection de doublon lors des ouvertures d'espace", self, category: "1) Ouverture d'espace")

    doc.start_section("Côté agent")
    doc.add_text("Contexte: Je suis un agent qui n'a jamais utilisé RDV Service Public")

    visit "http://www.rdv-service-public-test.localhost/"
    doc.add_screenshot(page,
                       text: "Je clique sur 'Ouvrir un espace'",
                       wait_for: "Ouvrir un espace")

    click_on "Ouvrir un espace"
    doc.add_screenshot(page,
                       text: "Une page m'explique qu'il faut que je me ProConnecte.",
                       wait_for: "Pour ouvrir votre espace, commencez par vous identifier avec ProConnect.")

    # ProConnect ne marche pas en tests, donc on triche en faisant un login par email et mot de passe
    visit new_agent_session_url(host:  "http://www.rdv-service-public-test.localhost")
    fill_in "Adresse email", with: agent.email
    fill_in "Mot de passe", with: agent.password
    click_on "Se connecter"

    doc.add_screenshot(page, text: "S'il existe déjà une autre organisation dont un admin a le même domaine d'adresse email ou siret que moi, je vois cette page de gestion des doublons.",
                             wait_for: "Pour commencer")
  end
end
