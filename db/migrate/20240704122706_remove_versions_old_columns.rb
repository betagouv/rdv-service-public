class RemoveVersionsOldColumns < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      remove_column :versions, :old_object, :text
      remove_column :versions, :old_object_changes, :text
    end
  end
end
