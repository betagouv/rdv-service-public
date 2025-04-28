class ChangeAgentDefaultNotificationLevel < ActiveRecord::Migration[7.1]
  def change
    change_column_default :agents, :rdv_notifications_level, from: "others", to: "all"
  end
end
