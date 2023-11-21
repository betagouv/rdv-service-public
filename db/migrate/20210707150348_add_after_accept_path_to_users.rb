class AddAfterAcceptPathToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :after_accept_path, :string
  end
end
