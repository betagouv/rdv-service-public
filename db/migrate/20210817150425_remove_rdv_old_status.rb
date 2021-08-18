# frozen_string_literal: true

class RemoveRdvOldStatus < ActiveRecord::Migration[6.0]
  def change
    remove_column :rdvs, :old_status, :integer, default: 0
  end
end
