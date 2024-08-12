class PrivilegeParentIdentifier::ByAgentTerritorialRole
  def initialize(version, parent_agent)
    @version = version
    @parent_agent = parent_agent
  end

  def identified?
    parent_territorial_role = AgentTerritorialRole.find_by(agent_id: @parent_agent.id, territory_id: version.territory_id)

    if parent_territorial_role

      # Les versions sur cette table ont été ajoutées dans une pr du 27/6/2023 https://github.com/betagouv/rdv-service-public/pull/3579
      parent_territorial_role_created_at = parent_territorial_role.versions.where(event: :create)&.first&.created_at || Date.new(2023, 6, 27)

      if parent_territorial_role_created_at < privilege_creation_version.created_at
        true
      end
    end
  end
end
