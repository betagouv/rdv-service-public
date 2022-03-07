# frozen_string_literal: true

class RemoveOldRdvLocation < ActiveRecord::Migration[6.1]
  def change
    rename_column :rdvs, :location, :old_location
  end
end
