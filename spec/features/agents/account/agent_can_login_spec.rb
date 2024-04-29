RSpec.describe "Agent can login" do
  it "updates last_sign_in_at attribute" do
    agent = create(:agent, password: "correcthorse", last_sign_in_at: 2.weeks.ago)
    visit new_agent_session_path
    fill_in "Email", with: agent.email
    fill_in "password", with: "correcthorse"

    # On utilise 10 secondes car la spec est parfois lente en CI et devient flaky
    expect { click_on "Se connecter" }.to change { agent.reload.last_sign_in_at }
      .from(be_within(10.seconds).of(2.weeks.ago))
      .to(be_within(10.seconds).of(Time.zone.now))
  end
end
