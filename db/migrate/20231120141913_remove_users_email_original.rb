class RemoveUsersEmailOriginal < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :email_original, :string
  end
end
