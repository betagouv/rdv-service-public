# Ce fichier reprend l'idée d'une doc swagger, mais pour communiquer à l'équipe non tech
RSpec.describe "Ouverture d'un espace" do
  specify do
    Capybara.current_driver = :desktop

    scenar = SpecToDoc.build_scenario(self.class.top_level_description)
    scenar.add_text("Pour un agent qui se crée un compte")

    visit "http://www.rdv-mairie-test.localhost/"
    scenar.add_screenshot(page)

    scenar.add_text("Cliquer sur 'Créer un espace'")
    click_on "Créer un espace"
    expect(page).to have_content("Connexion agent à")
    scenar.add_screenshot(page)

    scenar.add_text("Se connecter via ProConnect")

    SpecToDoc.render
  end
end
