class MoveAgentRoleToOrganisationJoinTable < ActiveRecord::Migration[6.0]
  def up
    add_column :agents_organisations, :id, :primary_key
    add_column :agents_organisations, :level, :string
    AgentRole.includes(:agent).each do |agent_role|
      mapped_role = { user: :basic, admin: :admin }[agent_role.agent.role.to_sym]
      agent_role.update!(level: mapped_role)
    end
    change_column_null :agents_organisations, :level, false
    remove_column :agents, :role
  end
end
