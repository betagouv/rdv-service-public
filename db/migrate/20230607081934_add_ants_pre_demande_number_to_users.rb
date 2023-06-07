# frozen_string_literal: true

class AddAntsPreDemandeNumberToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :ants_pre_demande_number, :string
  end
end
