# frozen_string_literal: true

class AddExpireToAbsence < ActiveRecord::Migration[6.0]
  def change
    add_column :absences, :expired_cached, :boolean, null: false, default: false
  end
end
