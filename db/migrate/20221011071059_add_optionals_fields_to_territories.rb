# frozen_string_literal: true

class AddOptionalsFieldsToTerritories < ActiveRecord::Migration[6.1]
  def change
    add_column :territories, :enable_waiting_room_mail_field, :boolean, default: false
    add_column :territories, :enable_waiting_room_color_field, :boolean, default: false
  end
end
