class DeleteUnusedColumns < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      remove_column :motifs, :legacy_bookable_publicly, :boolean, default: false, null: false
      remove_column :motifs, :old_location_type, :integer, default: 0, null: false

      remove_column :lieux, :old_address, :string
      remove_column :lieux, :old_enabled, :boolean, default: true, null: false

      remove_column :rdvs, :old_location, :string
    end
  end
end
