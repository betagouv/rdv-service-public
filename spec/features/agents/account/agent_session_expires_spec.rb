RSpec.describe "expiration de la session agent" do
  let(:password) { "CorrectH0rse!" }
  let!(:agent) { create(:agent, password: password, password_confirmation: password) }

  def expect_to_be_logged_in
    visit agents_preferences_path
    expect(page).to have_content("Préférences de notifications")
  end

  def expect_to_be_logged_out
    visit agents_preferences_path
    expect(page).to have_content("Entrez votre email et votre mot de passe")
  end

  # pour les agents il y a 2 niveaux de timeouts d'inactivité redondants :
  # - 8 heures côté devise via timeoutable
  # - 8 heures côté expiration cookie vérifiée par Rails (cf config/application.rb)
  # or dans les specs les cookies sont configurés pour ne pas expirer cf config/environments/test.rb
  # donc on teste en fait ici uniquement l'expiration niveau devise
  it "is done 8 hours after last visit" do
    login_time = Time.zone.parse("2024-01-01 12:00")
    travel_to(login_time)
    visit new_agent_session_path
    fill_in "Adresse email", with: agent.email
    fill_in "Mot de passe", with: password
    click_on "Se connecter"
    expect_to_be_logged_in

    travel_to(Time.zone.parse("2024-01-01 16:00")) # 4 hours after last visit
    expect_to_be_logged_in

    travel_to(Time.zone.parse("2024-01-01 23:55")) # almost 8 hours after last visit
    expect_to_be_logged_in

    travel_to(Time.zone.parse("2024-01-02 08:00")) # 8 hours and 5 minutes after last visit
    expect_to_be_logged_out
  end

  it "is done when the agent is deleted" do
    visit new_agent_session_path
    fill_in "Adresse email", with: agent.email
    fill_in "Mot de passe", with: password
    click_on "Se connecter"
    expect_to_be_logged_in

    agent.soft_delete

    expect_to_be_logged_out
    expect(page).to have_content("Votre compte a été supprimé !")
  end
end
