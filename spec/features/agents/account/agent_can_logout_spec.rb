RSpec.describe "Agent can logout" do
  let!(:agent) { create(:agent) }

  it "redirects to the login page" do
    visit new_agent_session_path
    fill_in "Email", with: agent.email
    fill_in "password", with: "Correcth0rse!"
    click_on "Se connecter"
    click_on "Se déconnecter"
    expect(page).to have_current_path(new_agent_session_path, ignore_query: true)
  end
end
