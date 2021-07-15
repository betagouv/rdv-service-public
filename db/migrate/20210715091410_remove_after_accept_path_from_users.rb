class RemoveAfterAcceptPathFromUsers < ActiveRecord::Migration[6.0]
  def change
    remove_column :users, :after_accept_path
  end
end
