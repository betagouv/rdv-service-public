class RenameRdvsUsersToParticipations < ActiveRecord::Migration[7.0]
  def change
    rename_table :rdvs_users, :participations
    rename_column :prescripteurs, :rdvs_user_id, :participation_id
    rename_index :participations, :index_rdvs_users_on_invited_by, :index_participations_on_invited_by
  end
end
