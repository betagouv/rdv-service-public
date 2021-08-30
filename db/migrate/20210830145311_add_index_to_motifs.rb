# frozen_string_literal: true

class AddIndexToMotifs < ActiveRecord::Migration[6.0]
  def change
    add_index :motifs, :reservable_online
  end
end
