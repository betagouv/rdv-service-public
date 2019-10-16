class RemoveVaDandUsersLimitFromMotif < ActiveRecord::Migration[6.0]
  def change
    remove_column :motifs, :at_home
    remove_column :motifs, :max_users_limit
    remove_column :rdvs, :max_users_limit 
  end
end
