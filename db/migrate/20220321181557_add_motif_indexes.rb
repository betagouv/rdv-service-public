# frozen_string_literal: true

class AddMotifIndexes < ActiveRecord::Migration[6.1]
  def change
    add_index :motifs, :collectif
    add_index :motifs, :visibility_type
  end
end
