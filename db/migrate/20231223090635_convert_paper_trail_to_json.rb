# See https://github.com/paper-trail-gem/paper_trail/blob/v12.3.0/README.md#convert-existing-yaml-data-to-json
class ConvertPaperTrailToJson < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      # les rows existants sont marqués "non migrés"
      add_column :versions, :migrated_to_json, :boolean, null: false, default: false

      rename_column :versions, :object, :old_object
      add_column :versions, :object, :jsonb

      rename_column :versions, :object_changes, :old_object_changes
      add_column :versions, :object_changes, :jsonb

      # les rows ajoutés à partir de maintenant sont marquée "migrés" car ils utilisent la nouvelle colonne JSONB
      change_column_default :versions, :migrated_to_json, from: false, to: true
    end
  end
end
