# frozen_string_literal: true

class MakeRdvsUsersUnique < ActiveRecord::Migration[6.1]
  def change
    add_index :rdvs_users, %i[rdv_id user_id], unique: true
    add_index :agents_rdvs, %i[agent_id rdv_id], unique: true
  end
end
