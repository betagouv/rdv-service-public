class PrivilegeParentIdentifier::ByTerritorialRoleVersion
  def initialize(version, parent_agent)
    @version = version
    @parent_agent = parent_agent
  end

  def identified?
    territorial_roles_not_deleted_at_time_of_version_creation.any?
  end

  def territorial_roles_not_deleted_at_time_of_version_creation
    access_rights_ids.select do |id|
      PaperTrail::Version.where(event: %i[update destroy], item_type: "AgentTerritorialRole", item_id: id).none?
    end
  end

  def access_rights_ids
    possible_parent_agent_territorial_role_versions.pluck(:item_id)
  end

  def possible_parent_agent_territorial_role_versions
    PaperTrail::Version.where(event: :create, item_type: "AgentTerritorialRole")
      .where("object_changes->'agent_id'->1 = ?", @parent_agent.id.to_s)
      .where("object_changes->'territory_id'->1 = ?", @version.territory_id.to_s)
  end
end
