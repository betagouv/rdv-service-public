class PrivilegeParentIdentifier::ByAgentTerritorialRole
  def initialize(version, parent_agent)
    @version = version
    @parent_agent = parent_agent
  end

  def identified?
    parent_territorial_role = AgentTerritorialRole.find_by(agent_id: @parent_agent.id, territory_id: @version)
    return unless parent_territorial_role

    # On a commencé à avoir des versions sur cette table le 27/6/2023
    parent_territorial_role_created_at = parent_territorial_role.versions.find_by(event: :create)&.created_at || Date.new(2023, 6, 27)

    parent_territorial_role_created_at < @version.created_at
  end
end
