# frozen_string_literal: true

describe "Agent can configure their preferences" do
  let!(:agent) do
    create(
      :agent,
      rdv_notifications_level: "soon",
      plage_ouverture_notification_level: "all",
      absence_notification_level: "all"
    )
  end

  before do
    login_as(agent, scope: :agent)
    visit agents_preferences_path
  end

  it "update preferences" do
    find(:radio_button, "agent_rdv_notifications_level_all", checked: false)
    find(:radio_button, "agent_rdv_notifications_level_soon", checked: true)
    find(:radio_button, "agent_plage_ouverture_notification_level_all", checked: true)
    find(:radio_button, "agent_plage_ouverture_notification_level_none", checked: false)
    find(:radio_button, "agent_absence_notification_level_all", checked: true)
    find(:radio_button, "agent_absence_notification_level_none", checked: false)

    choose :agent_rdv_notifications_level_all
    choose :agent_plage_ouverture_notification_level_none
    choose :agent_absence_notification_level_none
    click_button "Enregistrer"

    find(:radio_button, "agent_rdv_notifications_level_all", checked: true)
    find(:radio_button, "agent_rdv_notifications_level_soon", checked: false)
    find(:radio_button, "agent_plage_ouverture_notification_level_all", checked: false)
    find(:radio_button, "agent_plage_ouverture_notification_level_none", checked: true)
    find(:radio_button, "agent_absence_notification_level_all", checked: false)
    find(:radio_button, "agent_absence_notification_level_none", checked: true)
  end
end
