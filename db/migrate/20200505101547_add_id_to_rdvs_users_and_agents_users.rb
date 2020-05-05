class AddIdToRdvsUsersAndAgentsUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :rdvs_users, :id, :primary_key
    add_column :agents_rdvs, :id, :primary_key
  end
end
