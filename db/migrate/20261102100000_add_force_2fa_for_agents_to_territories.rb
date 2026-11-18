class AddForce2faForAgentsToTerritories < ActiveRecord::Migration[8.0]
  def change
    add_column :territories, :force_2fa_for_agents, :boolean, default: false, null: false,
                                                              comment: "Impose la double authentification à la connexion pour tous les agents de l'espace (cf. AgentSensitiveAccountCalculator)"
  end
end
