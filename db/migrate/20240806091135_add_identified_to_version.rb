class AddIdentifiedToVersion < ActiveRecord::Migration[7.0]
  def change
    add_column :versions, :identified, :boolean, null: false, default: false
  end
end
