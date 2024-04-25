RSpec.describe "Agent session expiration" do
  let(:password) { Faker::Internet.password(min_length: 12) }
  let!(:agent) { create(:agent, password: password, password_confirmation: password) }

  def expect_to_be_logged_in
    visit agents_preferences_path
    expect(page).to have_content("Préférences de notifications")
  end

  def expect_to_be_logged_out
    visit agents_preferences_path
    expect(page).to have_content("Se connecter")
  end

  it "is done 14 days after last visit" do
    login_time = Time.zone.parse("2024-01-01 12:00")
    travel_to(login_time)
    visit new_agent_session_path
    fill_in "Email", with: agent.email
    fill_in "password", with: password
    click_on "Se connecter"
    expect_to_be_logged_in

    last_visit_time = login_time + 3.days
    travel_to(last_visit_time)
    expect_to_be_logged_in

    last_visit_time += 13.days + 22.hours
    travel_to(last_visit_time)
    expect_to_be_logged_in

    last_visit_time += 14.days + 10.seconds
    travel_to(last_visit_time)
    expect_to_be_logged_out
  end
end
