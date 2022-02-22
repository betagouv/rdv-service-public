# frozen_string_literal: true

class AddAgentsDisplaySaturdays < ActiveRecord::Migration[6.1]
  def change
    add_column :agents, :display_saturdays, :boolean, default: false
  end
end
