class PrivilegeParentIdentifier::ByDeletedAgentRoleVersion
  def initialize(version, parent_agent)
    @version = version
    @parent_agent = parent_agent
  end

  def identified?
    return false unless @version.no_territory_privilege?

    agent_roles_without_any_modifications.any?
  end

  def agent_roles_without_any_modifications
    agent_role_ids.select do |id|
      PaperTrail::Version.where(event: %i[update create], item_type: "AgentRole", item_id: id).none?
    end
  end

  def agent_role_ids
    possible_parent_agent_role_deletion_versions.pluck(:item_id)
  end

  # TODO: voir s'il vaut mieux utiliser une méthode similaire à #versions_for_agent_roles_created_at_the_same_time
  def possible_parent_agent_role_deletion_versions
    PaperTrail::Version.where(event: :destroy, item_type: "AgentRole")
      .where("object_changes->'agent_id'->0 = ?", @parent_agent.id.to_s)
      .where("created_at > ?", @version.created_at)
      .select do |version|
      organisation = Organisation.find_by(id: version.object_changes["organisation_id"].first)
      organisation&.territory_id = @version.territory_id && version.object_changes["access_level"].first == "admin"
    end
  end
end
