# frozen_string_literal: true

class CreateMotifCategories < ActiveRecord::Migration[7.0]
  def up
    create_table :motif_categories do |t|
      t.string :name, null: false
      t.string :short_name, null: false

      t.timestamps
    end
    add_index :motif_categories, :name, unique: true
    add_index :motif_categories, :short_name, unique: true

    add_reference :motifs, :motif_category, foreign_key: true

    create_join_table :motif_categories, :territories do |t|
      t.index %i[motif_category_id territory_id], unique: true, name: "index_motif_cat_territories_on_motif_cat_id_and_territory_id"
    end

    populate_tables
  end

  def down
    drop_join_table :motif_categories, :territories
    remove_reference :motifs, :motif_category, foreign_key: true
    drop_table :motif_categories
  end

  def categories
    [
      {
        name: "RSA orientation",
        short_name: "rsa_orientation",
      },
      {
        name: "RSA accompagnement",
        short_name: "rsa_accompagnement",
      },
      {
        name: "RSA accompagnement social",
        short_name: "rsa_accompagnement_social",
      },
      {
        name: "RSA accompagnement socio-pro",
        short_name: "rsa_accompagnement_sociopro",
      },
      {
        name: "RSA orientation sur plateforme téléphonique",
        short_name: "rsa_orientation_on_phone_platform",
      },
      {
        name: "RSA signature CER",
        short_name: "rsa_cer_signature",
      },
      {
        name: "RSA offre insertion pro",
        short_name: "rsa_insertion_offer",
      },
      {
        name: "RSA suivi",
        short_name: "rsa_follow_up",
      },
      {
        name: "RSA Main Tendue",
        short_name: "rsa_main_tendue",
      },
      {
        name: "RSA Atelier collectif",
        short_name: "rsa_atelier_collectif_mandatory",
      },
      {
        name: "RSA SPIE",
        short_name: "rsa_spie",
      },
      {
        name: "RSA Information d'intégration",
        short_name: "rsa_integration_information",
      },
      {
        name: "RSA Atelier compétences",
        short_name: "rsa_atelier_competences",
      },
      {
        name: "RSA Atelier rencontres professionnelles",
        short_name: "rsa_atelier_rencontres_pro",
      },
    ]
  end

  def populate_tables
    # Create existing MotifCategories
    categories.each do |category|
      MotifCategory.create(category)
    end

    # Filled motif_category_id on motifs with existing category enum column
    Motif.where.not(category: nil).each do |motif|
      motif_category = MotifCategory.find_by(short_name: motif.category)
      motif.motif_category_id = motif_category.id
      motif.save
    end

    # Link Territories to all MotifCategories for existing territories with category_field enabled
    Territory.where(enable_motif_categories_field: true).each do |territory|
      MotifCategory.all.each do |motif_category|
        territory.motif_categories << motif_category
      end
    end
  end
end
