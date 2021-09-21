# frozen_string_literal: true

class AddCityCodeAndPostCodeAndCityNameToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :city_code, :string
    add_column :users, :post_code, :string
    add_column :users, :city_name, :string
  end
end
