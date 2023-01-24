# frozen_string_literal: true

class AddOutlookDisconnectInProgressToAgent < ActiveRecord::Migration[7.0]
  def change
    add_column :agents, :outlook_disconnect_in_progress, :boolean, null: false, default: false
  end
end
