# frozen_string_literal: true

class AddAgentsNotificationsLevel < ActiveRecord::Migration[6.0]
  def change
    create_enum :agents_rdv_notifications_level, %i[all others soon none]
    add_column :agents, :rdv_notifications_level, :agents_rdv_notifications_level, optional: false, default: :soon
  end
end
