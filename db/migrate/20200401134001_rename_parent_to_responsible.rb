class RenameParentToResponsible < ActiveRecord::Migration[6.0]
  def change
    rename_column :users, :parent_id, :responsible_id
  end
end
