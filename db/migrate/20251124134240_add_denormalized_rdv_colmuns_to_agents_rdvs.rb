class AddDenormalizedRdvColmunsToAgentsRdvs < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_column :agents_rdvs, :readonly_rdv_starts_at, :datetime, comment: "Colonne indexée et utilisée en lecture"
    add_column :agents_rdvs, :readonly_rdv_ends_at, :datetime, comment: "Colonne indexée et utilisée en lecture"
    add_column :agents_rdvs, :readonly_rdv_status, :rdv_status, comment: "Colonne indexée et utilisée en lecture"

    reversible do |direction|
      direction.up do
        AgentsRdv.all.includes(:rdv).find_each do |agents_rdv|
          agents_rdv.update_columns(
            readonly_rdv_starts_at: agents_rdv.rdv.starts_at,
            readonly_rdv_ends_at: agents_rdv.rdv.ends_at,
            readonly_rdv_status: agents_rdv.rdv.status
          )
        end
      end
    end

    add_index :agents_rdvs, "agent_id, tsrange(readonly_rdv_starts_at, readonly_rdv_ends_at, '[)'::text), readonly_rdv_status", name: "calculator_index", algorithm: :concurrently
  end
end
