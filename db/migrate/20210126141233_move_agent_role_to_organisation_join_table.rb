class MoveAgentRoleToOrganisationJoinTable < ActiveRecord::Migration[6.0]
  def up
    add_column :agents_organisations, :id, :primary_key
    add_column :agents_organisations, :level, :string, default: "basic"
    AgentRole.includes(:agent).each do |agent_role|
      mapped_role = {
        0 => AgentRole::LEVEL_BASIC, # was user
        1 => AgentRole::LEVEL_ADMIN
      }[agent_role.agent.role]
      agent_role.update!(level: mapped_role)
    end
    change_column_null :agents_organisations, :level, false
  end

  def down
    # data will be lost! only executable a few instants after a failed upgrade
    remove_column :agents_organisations, :id
    remove_column :agents_organisations, :level
  end
end
