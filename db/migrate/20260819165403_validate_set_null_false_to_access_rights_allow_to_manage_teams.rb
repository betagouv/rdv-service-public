class ValidateSetNullFalseToAccessRightsAllowToManageTeams < ActiveRecord::Migration[8.0]
  def up
    validate_check_constraint :agent_territorial_access_rights, name: "agent_territorial_access_rights_allow_to_manage_teams_null"
    change_column_null :agent_territorial_access_rights, :allow_to_manage_teams, false
    remove_check_constraint :agent_territorial_access_rights, name: "agent_territorial_access_rights_allow_to_manage_teams_null"
  end

  def down
    add_check_constraint :agent_territorial_access_rights, "allow_to_manage_teams IS NOT NULL", name: "agent_territorial_access_rights_allow_to_manage_teams_null", validate: false
    change_column_null :agent_territorial_access_rights, :allow_to_manage_teams, true
  end
end
