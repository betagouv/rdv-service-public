RSpec.describe "Impersonating an agent" do
  stub_env_with(SIGN_IN_AS_ALLOWED: "true")

  let!(:super_admin) { create(:super_admin) }
  let!(:agent) { create(:agent, password: "Correcth0rse!") }
  let!(:agent_organisation) { create(:organisation, agents: [agent]) }

  it "works" do
    login_as(super_admin, scope: :super_admin)
    visit super_admins_agent_path(agent)
    click_on "Se logger en tant que"
    expect(page).to have_current_path("/admin/organisations/#{agent_organisation.id}/agent_agendas/#{agent.id}")
    expect(page).to have_content(agent.full_name)
  end

  describe "telling Sentry that the agent is impersonating" do
    # Display 404 instead of letting the ActiveRecord::RecordNotFound bubble up to the spec
    around do |example|
      Rails.application.configure { config.action_dispatch.show_exceptions = true }
      example.run
      Rails.application.configure { config.action_dispatch.show_exceptions = false }
    end

    let!(:other_organisation) { create(:organisation) }

    it "works" do
      login_as(super_admin, scope: :super_admin)
      visit super_admins_agent_path(agent)
      click_on "Se logger en tant que"

      # Simulate clicking on a
      Capybara.current_session.driver.header "Referer", "https://www.rdv-solidarites-test.localhost#{page.current_path}"
      expect { visit "/admin/organisations/#{other_organisation.id}" }.to change(sentry_events, :size).by(1)
      expect(page).to have_content("Page introuvable")
      expect(sentry_events.last.tags[:impersonating]).to eq("true")
    end
  end
end
