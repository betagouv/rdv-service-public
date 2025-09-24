RSpec.describe "Ouverture d'un espace", js: true do
  specify do
    doc = Autodoc.start_scenario("Ouverture d'un espace", self)

    doc.start_section("Côté agent")
    doc.add_text("Contexte: Je suis un agent qui n'a jamais utilisé RDV Service Public")

    visit "http://www.rdv-mairie-test.localhost/"

    doc.add_screenshot(page, text: "Je clique sur 'Créer un espace'", wait_for: "Créer un espace")

    click_on "Créer un espace"

    fill_in "Adresse email", with: "francis@factice.org"
    fill_in "Mot de passe", with: "CorrectBatteryH0rseStaple!"
    click_on "Se connecter"

    click_on "Demander à ouvrir un espace"
    fill_in("Nom de votre première organisation", with: "CCAS de Montreuil")

    doc.add_screenshot(
      page,
      text: "L'équipe déploiement a ensuite reçu la demande de création de compte dans le super admin",
      wait_for: "Votre demande a bien été enregistrée."
    )

    expect(Agent.last).to have_attributes(email: "francis@factice.org")
  end
end
