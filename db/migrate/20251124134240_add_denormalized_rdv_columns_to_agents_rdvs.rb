class AddDenormalizedRdvColumnsToAgentsRdvs < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_column :agents_rdvs, :calculator_rdv_starts_at, :datetime, comment: "Colonne indexée et utilisée en pour optimiser les performances du calculateur de créneaux"
    add_column :agents_rdvs, :calculator_rdv_ends_at, :datetime, comment: "Colonne indexée et utilisée en pour optimiser les performances du calculateur de créneaux"
    add_column :agents_rdvs, :calculator_rdv_not_cancelled_and_in_the_future, :boolean, comment: "Colonne indexée et utilisée en pour optimiser les performances du calculateur de créneaux"

    reversible do |direction|
      unless Rails.env.production? # En production la migration prend trop longtemps, donc on fera tourner manuellement scripts/initialize_calculator_index_values.rb
        direction.up do
          AgentsRdv.update_all <<~SQL.squish
            calculator_rdv_starts_at = rdvs.starts_at,
            calculator_rdv_ends_at = rdvs.ends_at,
            calculator_rdv_not_cancelled_and_in_the_future = (rdvs.ends_at >= NOW() AND rdvs.status IN ('unknown', 'seen', 'noshow'))
            FROM rdvs WHERE rdvs.id = agents_rdvs.rdv_id
          SQL
        end
      end
    end

    add_index(
      :agents_rdvs,
      "agent_id, tsrange(calculator_rdv_starts_at, calculator_rdv_ends_at, '[)'::text)", # Le "::text" semble nécessaire pour faire marcher la requête
      where: "calculator_rdv_not_cancelled_and_in_the_future",
      include: %w[calculator_rdv_starts_at calculator_rdv_ends_at],
      name: "calculator_index",
      algorithm: :concurrently
    )
  end
end
