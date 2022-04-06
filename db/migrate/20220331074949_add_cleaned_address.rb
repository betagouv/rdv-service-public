# frozen_string_literal: true

class AddCleanedAddress < ActiveRecord::Migration[6.1]
  def change
    add_column :lieux, :cleaned_address, :string
  end
end
