# frozen_string_literal: true

class AddRdvsEndsAt < ActiveRecord::Migration[6.0]
  def change
    add_column :rdvs, :ends_at, :datetime

    up_only do
      Rdv.update_all("ends_at = starts_at + duration_in_min * INTERVAL '1 minute'")
    end

    add_index :rdvs, :ends_at

    change_column_null :rdvs, :ends_at, false
    rename_column :rdvs, :duration_in_min, :old_duration_in_min
    change_column_null :rdvs, :old_duration_in_min, true
  end
end
