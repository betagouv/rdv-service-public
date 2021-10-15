# frozen_string_literal: true

class AddIndexMotifLocationType < ActiveRecord::Migration[6.0]
  def change
    add_index :motifs, :location_type
  end
end
