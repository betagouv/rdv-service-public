RSpec.describe "Un usager peut se logger via un mot de passe" do
  before { create(:user, email: "marco@lolmail.fr", first_name: "Marco", password: "Rdvservicepublictest1!") }

  specify do
    visit new_user_session_path
    find("a", text: /par mot de passe/).click
    fill_in "Adresse email", with: "marco@lolmail.fr"
    fill_in "Mot de passe", with: "Rdvservicepublictest1!"
    within("main") { click_on "Se connecter" }
    expect(page).to have_content("Connexion réussie")
    expect(page).to have_current_path("/users/rdvs")
  end
end
