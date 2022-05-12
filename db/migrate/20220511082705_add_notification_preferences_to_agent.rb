# frozen_string_literal: true

class AddNotificationPreferencesToAgent < ActiveRecord::Migration[6.1]
  def change
    create_enum :agents_plage_ouverture_notification_level, %i[all none]
    create_enum :agents_absence_notification_level, %i[all none]

    add_column :agents, :plage_ouverture_notification_level, :agents_plage_ouverture_notification_level, optional: false, default: :all
    add_column :agents, :absence_notification_level, :agents_absence_notification_level, optional: false, default: :all
  end
end
