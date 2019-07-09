class AddLimitUsersToMotifs < ActiveRecord::Migration[5.2]
  def change
    remove_column :motifs, :accept_multiple_pros
    remove_column :motifs, :accept_multiple_users
    add_column :motifs, :max_users_limit, :integer
  end
end
