# frozen_string_literal: true

class AddEnableCaseNumberToTerritory < ActiveRecord::Migration[6.1]
  def change
    add_column :territories, :enable_case_number, :boolean, default: false
    add_column :territories, :enable_address_details, :boolean, default: false
    add_column :users, :case_number, :string
    add_column :users, :address_details, :string
  end
end
