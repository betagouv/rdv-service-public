# Ce fichier reprend l'idée d'une doc swagger, mais pour communiquer à l'équiep non tech
RSpec.describe "Ouverture d'un espace" do
  specify do
    scenar = SpecToDoc::Scenario.new(self.class.top_level_description)
    scenar.add_step("Pour un agent qui se crée un compte")

    visit "/"
    scenar.add_screenshot

    scenar.add_step("Cliquer sur 'Créer un espace'")
    click_on "Créer un espace"
    sleep 0.2
    scenar.add_screenshot

    scenar.add_step("Se connecter via ProConnect")
  end
end
