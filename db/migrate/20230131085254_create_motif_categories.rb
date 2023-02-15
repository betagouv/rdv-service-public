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

    remove_column :motifs, :category, :motif_category
    remove_column :territories, :enable_motif_categories_field
    drop_enum :motif_category
  end

  def down
    create_enum :motif_category, %w[
      rsa_orientation
      rsa_accompagnement
      rsa_orientation_on_phone_platform
      rsa_cer_signature
      rsa_insertion_offer
      rsa_follow_up
      rsa_accompagnement_social
      rsa_accompagnement_sociopro
      rsa_main_tendue
      rsa_atelier_collectif_mandatory
      rsa_spie
      rsa_integration_information
      rsa_atelier_competences
      rsa_atelier_rencontres_pro
    ]

    add_column :territories, :enable_motif_categories_field, :boolean, default: false
    Territory.includes(:motif_categories).where.not(motif_categories: { id: nil }).each do |territory|
      territory.update(enable_motif_categories_field: true)
    end

    drop_join_table :motif_categories, :territories
    add_column :motifs, :category, :motif_category

    execute(<<-SQL.squish
      UPDATE motifs
      SET category = (
        SELECT motif_categories.short_name::motif_category from motif_categories
        WHERE motifs.motif_category_id = motif_categories.id
      )
      WHERE motifs.motif_category_id IS NOT NULL
    SQL
           )

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
    execute(<<-SQL.squish
      UPDATE motifs
      SET motif_category_id = (
        SELECT motif_categories.id from motif_categories
        WHERE motifs.category = motif_categories.short_name::motif_category
      )
      WHERE motifs.category IS NOT NULL
    SQL
           )

    # Link Territories to all MotifCategories for existing territories with category_field enabled
    Territory.where(enable_motif_categories_field: true).each do |territory|
      MotifCategory.all.each do |motif_category|
        territory.motif_categories << motif_category
      end
    end
  end
end
