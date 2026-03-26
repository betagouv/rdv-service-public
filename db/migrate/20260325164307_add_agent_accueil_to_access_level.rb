class AddAgentAccueilToAccessLevel < ActiveRecord::Migration[8.0]
  def change
    add_enum_value :access_level, "agent_accueil"
  end
end
