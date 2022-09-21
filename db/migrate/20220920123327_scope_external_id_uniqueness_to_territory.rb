# frozen_string_literal: true

class ScopeExternalIdUniquenessToTerritory < ActiveRecord::Migration[6.1]
  def change
    remove_index :organisations, :external_id, unique: true
    add_index :organisations, %i[external_id territory_id], unique: true
  end
end
