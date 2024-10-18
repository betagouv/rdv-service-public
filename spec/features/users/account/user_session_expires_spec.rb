RSpec.describe "User session expiration" do
  let(:password) { "Rdvservicepublictest1!" }
  let!(:user) { create(:user, password: password, password_confirmation: password) }

  def expect_to_be_logged_in
    visit users_informations_path
    expect(page).to have_content("Mes informations")
  end

  def expect_to_be_logged_out
    visit users_informations_path
    expect(page).to have_content("Entrez votre email et votre mot de passe")
  end

  it "is done 30 minutes after last visit" do
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "password", with: password
    within("main") { click_on "Se connecter" }
    expect_to_be_logged_in

    travel_to(28.minutes.from_now)
    expect_to_be_logged_in

    travel_to(31.minutes.from_now)
    expect_to_be_logged_out
  end
end
