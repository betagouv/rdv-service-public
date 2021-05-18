# frozen_string_literal: true

describe "Agent can configure their preferences" do
  let!(:agent) { create(:agent, rdv_notifications_level: "soon") }

  before do
    login_as(agent, scope: :agent)
    visit agents_preferences_path
  end

  it "update preferences" do
    find(:radio_button, "agent_rdv_notifications_level_all", checked: false)
    find(:radio_button, "agent_rdv_notifications_level_soon", checked: true)
    choose "À chaque modification"
    click_button "Enregistrer"
    find(:radio_button, "agent_rdv_notifications_level_all", checked: true)
    find(:radio_button, "agent_rdv_notifications_level_soon", checked: false)
  end
end
