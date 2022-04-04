# frozen_string_literal: true

class AddCategoryToMotifs < ActiveRecord::Migration[6.1]
  def change
    create_enum :motif_category, %i[rsa_orientation rsa_accompagnement rsa_orientation_phone_platform]
    add_column :motifs, :category, :motif_category
    add_index :motifs, :category
  end
end
