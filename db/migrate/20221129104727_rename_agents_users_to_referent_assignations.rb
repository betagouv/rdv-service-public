# frozen_string_literal: true

class RenameAgentsUsersToReferentAssignations < ActiveRecord::Migration[7.0]
  def change
    rename_table :agents_users, :referent_assignations
    add_index :referent_assignations, %i[user_id agent_id], unique: true
  end
end
