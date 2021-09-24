# frozen_string_literal: true

class AddMissingIndexes < ActiveRecord::Migration[6.0]
  def change
    add_index :organisations, :name
    add_index :services, :name
    add_index :motifs, :name
    add_index :lieux, :name
    add_index :agents, :last_name
    add_index :users, :last_name
    add_index :agents_organisations, :level
    add_index :rdvs, :starts_at
  end
end
