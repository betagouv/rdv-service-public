class RenameForeignKeys < ActiveRecord::Migration[6.0]
  def change
    rename_column :plage_ouvertures, :pro_id, :agent_id
    rename_column :absences, :pro_id, :agent_id
    rename_table :pros_rdvs, :agents_rdvs
    rename_column :agents_rdvs, :pro_id, :agent_id
  end
end
