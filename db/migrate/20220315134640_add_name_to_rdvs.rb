# frozen_string_literal: true

class AddNameToRdvs < ActiveRecord::Migration[6.1]
  def change
    add_column :rdvs, :name, :string
  end
end
