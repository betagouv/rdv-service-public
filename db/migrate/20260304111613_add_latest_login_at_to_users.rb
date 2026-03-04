class AddLatestLoginAtToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :latest_login_at, :datetime
  end
end
