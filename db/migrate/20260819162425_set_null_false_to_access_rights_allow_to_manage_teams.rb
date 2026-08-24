class SetNullFalseToAccessRightsAllowToManageTeams < ActiveRecord::Migration[8.0]
  def change
    AgentTerritorialAccessRight.where(allow_to_manage_teams: nil).update_all(allow_to_manage_teams: false) # ça ne coûte rien

    add_check_constraint :agent_territorial_access_rights, "allow_to_manage_teams IS NOT NULL", name: "agent_territorial_access_rights_allow_to_manage_teams_null", validate: false
  end
end
