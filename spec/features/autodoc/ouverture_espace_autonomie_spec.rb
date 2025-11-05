# Les captures d'écran des emails dans autodoc causent des erreurs JS à cause d'images qui ne chargent pas correctement
# donc on désactive cette vérification pour ces specs
RSpec.describe "Ouverture d'un espace", ignore_js_errors: true, js: true do
  let!(:agent) { create(:agent, first_name: "Francis", last_name: "Factice", password: "c0rrecThorse!", email: "francis.factice@beta.gouv.fr") }

  around { |example| perform_enqueued_jobs { example.run } }

  specify do
    doc = Autodoc.start_scenario("Ouverture d'un espace en complète autonomie", self, accessibility_checks: false)

    doc.start_section("Côté agent")
    doc.add_text("Contexte: Je suis un agent qui n'a jamais utilisé RDV Service Public")

    visit "http://www.rdv-mairie-test.localhost/"
    doc.add_screenshot(page,
                       text: "Je clique sur 'Ouvrir un espace'",
                       wait_for: "Ouvrir un espace")

    click_on "Ouvrir un espace"
    doc.add_screenshot(page,
                       text: "Une page m'explique qu'il faut que je me ProConnecte.",
                       wait_for: "Pour ouvrir votre espace, commencez par vous identifier avec ProConnect.")

    # ProConnect ne marche pas en tests, donc on triche en faisant un login par email et mot de passe
    visit new_agent_session_url(host:  "http://www.rdv-mairie-test.localhost")
    fill_in "Adresse email", with: agent.email
    fill_in "Mot de passe", with: agent.password
    click_on "Se connecter"

    fill_in("Nom de votre organisation", with: "CCAS de Montreuil")

    doc.add_screenshot(page, text: "Je remplis le formulaire puis je valide", wait_for: "Nom de")

    click_on "Enregistrer"

    doc.add_screenshot(page,
                       text: "J'arrive dans mon espace RDV Service Public",
                       wait_for: "Pour commencer, vous pouvez créer votre premier motif de rendez-vous.")

    open_email(agent.email)
    expect(current_email.subject).to eq "Votre espace RDV Service Public est ouvert 🚀"

    doc.add_screenshot(current_email, text: "J'ai aussi reçu un email de confirmation")
  end
end
