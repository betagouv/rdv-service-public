class DeleteOldNotesFromUsers < ActiveRecord::Migration[6.0]
  def change
    remove_column :users, :old_notes
  end
end
