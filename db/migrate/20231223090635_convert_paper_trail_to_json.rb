# See https://github.com/paper-trail-gem/paper_trail/blob/v12.3.0/README.md#convert-existing-yaml-data-to-json
class ConvertPaperTrailToJson < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      rename_column :versions, :object, :old_object
      add_column :versions, :object, :jsonb

      rename_column :versions, :object_changes, :old_object_changes
      add_column :versions, :object_changes, :jsonb
    end
  end
end
