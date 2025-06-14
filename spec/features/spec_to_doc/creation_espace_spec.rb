# Ce fichier reprend l'idée d'une doc swagger, mais pour communiquer à l'équipe non tech
RSpec.describe "Ouverture d'un espace", js: true do
  let!(:agent) { create(:agent, :no_services, first_name: "Francis", last_name: "Factice", password: "c0rrecThorse!") }

  specify do
    doc = SpecToDoc.start_scenario("Ouverture d'un espace", self)

    doc.add_text("Contexte: Je suis un agent qui n'a jamais utilisé RDV Service Public")

    visit "http://www.rdv-mairie-test.localhost/"
    doc.add_screenshot(page,
                       text: "Je clique sur 'Créer un espace'",
                       wait_for: "Créer un espace")

    click_on "Créer un espace"
    doc.add_screenshot(page,
                       text: "Je me ProConnecte.",
                       wait_for: "Connexion agent à")

    # ProConnect ne marche pas en tests, donc on utilise l'email et le mot de passe
    fill_in "Adresse email", with: agent.email
    fill_in "Mot de passe", with: agent.password
    click_on "Se connecter"

    doc.add_screenshot(page,
                       text: "Je clique sur Demander à ouvrir un espace",
                       wait_for: "Pour commencer, aidez-nous à en savoir plus")

    click_on "Demander à ouvrir un espace"

    doc.add_screenshot(page, wait_for: "Nom de")

    fill_in("Nom de l’espace", with: "Commune de Montreuil")
    fill_in("Nom de votre première organisation", with: "CCAS de Montreuil")
    fill_in("Pour quel service souhaitez-vous gérer des rendez-vous ?", with: "Action Sociale")

    doc.add_screenshot(page,
                       text: "Je remplis le formulaire puis je valide")

    click_on "Envoyer la demande"

    doc.add_screenshot(page,
                       text: "L'équipe déploiement a ensuite reçu la demande de création de compte dans le super admin",
                       wait_for: "Votre demande a bien été enregistrée.")
  end
end
