class AddTerritoryTags < ActiveRecord::Migration[7.2]
  def change
    create_table :tags do |t|
      t.string :name
      t.timestamps
    end

    change_table_comment(:tags, from: nil, to: "Des tags pour catégoriser les espaces en fonctions des partenariats auxquels ils sont liés.")

    create_table :territory_tags do |t|
      t.references :territory, foreign_key: true, index: true
      t.references :tag, foreign_key: true, index: true

      t.timestamps
    end

    add_index :tags, :name, unique: true
    add_index :territory_tags, %i[territory_id tag_id], unique: true
  end
end
