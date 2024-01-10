class CleanupCreatedByMigration < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      add_check_constraint :rdvs, "created_by_type IS NOT NULL", name: "rdvs_created_by_type_null", validate: false
      add_check_constraint :participations, "created_by_type IS NOT NULL", name: "participations_created_by_type_null", validate: false

      remove_column :rdvs, :created_by, :integer, index: true
      remove_column :participations, :created_by, :created_by

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
