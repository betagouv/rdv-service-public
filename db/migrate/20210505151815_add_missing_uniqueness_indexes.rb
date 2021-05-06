class AddMissingUniquenessIndexes < ActiveRecord::Migration[6.0]
  def change
    add_index :file_attentes, %i[rdv_id user_id], unique: true
    add_index :sectors, %i[human_id territory_id], unique: true
    add_index :motifs, %i[name organisation_id location_type service_id],
              unique: true, where: "deleted_at IS NULL",
              name: "index_motifs_on_name_scoped" # the rails-generated name is too long, use a custom name.
    add_index :organisations, %i[name territory_id], unique: true
    add_index :organisations, %i[human_id territory_id], unique: true, where: "human_id IS NOT NULL"

    reversible do |dir|
      dir.up do
        add_index :services, "lower(name)", unique: true, name: "index_services_on_lower_name"
        add_index :services, "lower(short_name)", unique: true, name: "index_services_on_lower_short_name"
      end
      dir.down do
        # remove_index doesn't support the “lower” syntax, let’s just use the name.
        remove_index :services, name: "index_services_on_lower_name"
        remove_index :services, name: "index_services_on_lower_short_name"
      end
    end
  end
end
