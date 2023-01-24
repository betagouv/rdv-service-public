# frozen_string_literal: true

class AddOutlookCreateInProgressToAgentsRdv < ActiveRecord::Migration[7.0]
  def change
    add_column :agents_rdvs, :outlook_create_in_progress, :boolean, null: false, default: false
  end
end
