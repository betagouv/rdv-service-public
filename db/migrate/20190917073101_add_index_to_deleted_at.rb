class AddIndexToDeletedAt < ActiveRecord::Migration[5.2]
  def change
    add_index :motifs, :deleted_at
  end
end
