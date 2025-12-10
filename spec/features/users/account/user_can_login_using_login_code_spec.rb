RSpec.describe "User can login using 6-digits login code" do
  it "sends an email with the code and validates it" do
    email = "user@example.com"
    user = create(:user, email:)

    visit new_user_session_path
    fill_in "Adresse e-mail", with: email
    within("main") { click_on "Se connecter" }
    expect(page).to have_content("Veuillez saisir le code à 6 chiffre envoyé à #{email}")

    perform_enqueued_jobs
    open_email(email)
    expect(current_email.subject).to eq("Votre code de connexion est #{UserLoginCode.code_for(email)}")

    fill_in("Code à 6 chiffres", with: UserLoginCode.code_for(email))
    click_on "Valider"
    expect(page).to have_content("Connexion réussie")
    expect(page).to have_current_path("/users/rdvs")
    click_on "Vos informations"
    expect(page).to have_field("user_first_name", with: user.first_name)
  end
end
