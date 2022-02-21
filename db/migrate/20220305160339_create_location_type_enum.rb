# frozen_string_literal: true

class CreateLocationTypeEnum < ActiveRecord::Migration[6.1]
  def change
    remove_index :motifs, %i[name organisation_id location_type service_id],
                 unique: true, where: "deleted_at IS NULL", name: "index_motifs_on_name_scoped"

    remove_index :motifs, :location_type
    rename_column :motifs, :location_type, :old_location_type
    create_enum :location_type, %i[public_office home phone]
    add_column :motifs, :location_type, :location_type

    up_only do
      old_enum_values = { public_office: 0, phone: 1, home: 2 }
      old_enum_values.each do |name, int_value|
        Motif.where(old_location_type: int_value).update_all(location_type: name)
      end
    end

    add_index :motifs, :location_type
    change_column_default :motifs, :location_type, from: nil, to: :public_office
    change_column_null :motifs, :location_type, false

    add_index :motifs, %i[name organisation_id location_type service_id],
              unique: true, where: "deleted_at IS NULL", name: "index_motifs_on_name_scoped"
  end
end
