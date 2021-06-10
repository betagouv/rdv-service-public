# frozen_string_literal: true

class AddIndexToPlageOuverture < ActiveRecord::Migration[6.0]
  def change
    add_index :plage_ouvertures, :expired_cached
  end
end
