# frozen_string_literal: true

class CreateRdvStatusEnum < ActiveRecord::Migration[6.0]
  def change
    rename_column :rdvs, :status, :old_status

    create_enum :rdv_status, %w[unknown waiting seen excused revoked noshow]
    add_column :rdvs, :status, :rdv_status

    up_only do
      old_enum_values = { unknown: 0, waiting: 1, seen: 2, excused: 3, noshow: 4, revoked: 5 }
      old_enum_values.each do |name, int_value|
        Rdv.where(old_status: int_value).update_all(status: name)
      end
    end

    change_column_null :rdvs, :status, false # will fail if, by accident, some rows have a nil status.
    change_column_default :rdvs, :status, from: nil, to: :unknown

    add_index :rdvs, :status
  end
end
