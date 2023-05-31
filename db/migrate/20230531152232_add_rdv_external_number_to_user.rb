# frozen_string_literal: true

class AddRdvExternalNumberToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :rdv_external_number, :string
  end
end
