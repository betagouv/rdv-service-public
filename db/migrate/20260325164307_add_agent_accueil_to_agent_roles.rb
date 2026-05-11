class AddAgentAccueilToAgentRoles < ActiveRecord::Migration[8.0]
  def change
    add_column :agent_roles, :agent_accueil, :boolean, default: false, null: false
  end
end
