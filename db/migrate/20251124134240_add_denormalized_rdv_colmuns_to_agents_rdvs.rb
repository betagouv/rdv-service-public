class AddDenormalizedRdvColmunsToAgentsRdvs < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_column :agents_rdvs, :readonly_rdv_starts_at, :datetime, comment: "Colonne indexée et utilisée en lecture"
    add_column :agents_rdvs, :readonly_rdv_ends_at, :datetime, comment: "Colonne indexée et utilisée en lecture"
    add_column :agents_rdvs, :readonly_busy_in_the_future, :boolean, comment: "Colonne indexée et utilisée en lecture"

    reversible do |direction|
      unless Rails.env.production? # En production la migration prend trop longtemps, donc on fera tourner manuellement scripts/initialize_calculator_index_values.rb
        direction.up do
          AgentsRdv.update_all(
            "readonly_rdv_starts_at = rdvs.starts_at, readonly_rdv_ends_at = rdvs.ends_at, readonly_busy_in_the_future = (rdvs.starts_at >= NOW() AND rdvs.status IN ('unknown', 'seen', 'noshow')) FROM rdvs WHERE rdvs.id = agents_rdvs.rdv_id"
          )
        end
      end
    end

    add_index :agents_rdvs, "agent_id, readonly_rdv_starts_at, readonly_rdv_ends_at", name: "calculator_index", algorithm: :concurrently,
                                                                                      where: "readonly_busy_in_the_future"
  end
end
