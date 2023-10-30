class UpdateRdvNotificationsLevelDefault < ActiveRecord::Migration[7.0]
  def change
    change_column_default :agents, :rdv_notifications_level, from: "soon", to: "others"
  end
end
