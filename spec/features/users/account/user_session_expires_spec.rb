RSpec.describe "User session expiration" do
  let!(:user) { create(:user) }

  def expect_to_be_logged_in
    visit users_informations_path
    expect(page).to have_content("Mes informations")
  end

  def expect_to_be_logged_out
    visit users_informations_path
    expect(page).to have_content("Connexion")
  end

  # pour les usagers il y a 2 niveaux de timeouts d'inactivité redondants :
  # - 30 minutes côté devise via timeoutable (cf app/models/user.rb)
  # - 8 heures côté expiration cookie vérifiée par Rails (cf config/application.rb)
  # or dans les specs les cookies sont configurés pour ne pas expirer cf config/environments/test.rb
  # donc on teste en fait ici uniquement l'expiration niveau devise
  it "is done 30 minutes after last visit" do
    visit new_user_session_path
    login_via_6_digit_code(user.email)
    expect_to_be_logged_in

    travel_to(28.minutes.from_now)
    expect_to_be_logged_in

    travel_to(31.minutes.from_now)
    expect_to_be_logged_out
  end
end
