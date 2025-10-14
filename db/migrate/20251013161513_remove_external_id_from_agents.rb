class RemoveExternalIdFromAgents < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    safety_assured do
      remove_column :agents, :external_id, :string
    end
  end
end
