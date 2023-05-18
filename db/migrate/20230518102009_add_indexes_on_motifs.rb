# frozen_string_literal: true

class AddIndexesOnMotifs < ActiveRecord::Migration[7.0]
  def change
    add_index :motifs, :follow_up
    add_index :motifs, :sectorisation_level
    add_index :motifs, :bookable_by
  end
end
