RSpec.describe "Ouverture d'un espace", js: true do
  specify do
    visit "http://www.rdv-mairie-test.localhost/"

    click_on "Créer un espace"

    fill_in "Adresse email", with: "francis@factice.org"
    fill_in "Mot de passe", with: "CorrectBatteryH0rseStaple!"
    click_on "Se connecter"

    click_on "Demander à ouvrir un espace"
    fill_in("Nom de votre première organisation", with: "CCAS de Montreuil")

    expect(page).to have_content("Votre demande a bien été enregistrée.")

    expect(Agent.last).to have_attributes(email: "francis@factice.org")
  end
end
