RSpec.describe "User session expiration" do
  let(:password) { "Rdvservicepublictest1!" }
  let!(:user) { create(:user, password: password, password_confirmation: password) }

  def expect_to_be_logged_in
    visit users_informations_path
    expect(page).to have_content("Mes informations")
  end

  def expect_to_be_logged_out
    visit users_informations_path
    expect(page).to have_content("Se connecter par e-mail")
  end

  it "is done 30 minutes after last visit" do
    visit new_user_session_path
    fill_in "Adresse e-mail", with: user.email
    within("main") { click_on "Se connecter" }
    fill_in("Code à 6 chiffres", with: UserLoginCode.code_for(user.email))
    click_on "Valider"
    expect_to_be_logged_in

    travel_to(28.minutes.from_now)
    expect_to_be_logged_in

    travel_to(31.minutes.from_now)
    expect_to_be_logged_out
  end
end
