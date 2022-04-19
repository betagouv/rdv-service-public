# frozen_string_literal: true

class AddCategoryFieldToMotifs < ActiveRecord::Migration[6.1]
  def change
    create_enum :motif_category, %i[rsa_orientation rsa_accompagnement rsa_orientation_on_phone_platform]
    add_column :motifs, :category, :motif_category
    add_index :motifs, :category

    add_column :territories, :enable_motif_categories_field, :boolean, default: false
  end
end
