# frozen_string_literal: true

class RemoveOldColumns < ActiveRecord::Migration[6.1]
  def change
    remove_column :rdvs, :old_duration_in_min, :integer
    remove_column :users, :old_logement, :integer
    remove_column :users, :old_created_through, :string
  end
end
