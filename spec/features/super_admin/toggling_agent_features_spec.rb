RSpec.describe "Toggling agent features", js: true do
  let(:super_admin) { create :super_admin }
  let(:agent) { create :agent }

  before do
    login_as(super_admin, scope: :super_admin)
  end

  it "allows enabling then disabling a feature" do
    visit super_admins_agent_path(agent)

    within("tr", text: "rdv_invitations") do
      expect(page).to have_content("Désactivée")
      click_on "Activer"
    end

    expect(page).to have_content("rdv_invitations activé pour #{agent.email}")
    within("tr", text: "rdv_invitations") { expect(page).to have_content("Activée") }
    expect(agent.reload.feature_enabled?("rdv_invitations")).to be true

    within("tr", text: "rdv_invitations") { click_on "Désactiver" }

    expect(page).to have_content("rdv_invitations désactivé pour #{agent.email}")
    within("tr", text: "rdv_invitations") { expect(page).to have_content("Désactivée") }
    expect(agent.reload.feature_enabled?("rdv_invitations")).to be false
  end
end
