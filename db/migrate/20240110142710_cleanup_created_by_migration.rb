class CleanupCreatedByMigration < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      change_column_null :rdvs, :created_by_type, false
      change_column_null :participations, :created_by_type, false

      remove_index :rdvs, :created_by
      rename_column :rdvs, :created_by, :old_created_by
      rename_column :participations, :created_by, :old_created_by

      reversible do |direction|
        direction.up do
          remove_column :prescripteurs, :participation_id
        end
        direction.down do
          add_column :prescripteurs, :participation_id, :bigint
          add_index :prescripteurs, :participation_id, unique: true
          add_foreign_key :prescripteurs, :participations
        end
      end
    end
  end
end
