RSpec.describe "Agent session expiration" do
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

  it "is done 14 days after last visit" do
    login_time = Time.zone.parse("2024-01-01 12:00")
    travel_to(login_time)
    visit new_agent_session_path
    fill_in "Email", with: agent.email
    fill_in "password", with: password
    click_on "Se connecter"
    expect_to_be_logged_in

    travel_to(Time.zone.parse("2024-01-10 12:00")) # 10 days after last visit
    expect_to_be_logged_in

    travel_to(Time.zone.parse("2024-01-24 11:55")) # almost 14 days after last visit
    expect_to_be_logged_in

    travel_to(Time.zone.parse("2024-02-07 12:00")) # 14 days and 5 minutes after last visit
    expect_to_be_logged_out
  end

  it "is done when the agent is deleted" do
    visit new_agent_session_path
    fill_in "Email", with: agent.email
    fill_in "password", with: password
    click_on "Se connecter"
    expect_to_be_logged_in

    agent.soft_delete

    expect_to_be_logged_out
    expect(page).to have_content("Votre compte a été supprimé !")
  end
end
