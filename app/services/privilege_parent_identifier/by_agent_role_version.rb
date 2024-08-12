class PrivilegeParentIdentifier::ByAgentRoleVersion
  def initialize(version, parent_agent)
    @version = version
    @parent_agent = parent_agent
  end

  def identified?
    return false unless @version.no_territory_privilege?

    agent_roles_not_deleted_at_time_of_version_creation.any?
  end

  def agent_roles_not_deleted_at_time_of_version_creation
    agent_role_ids.select do |id|
      PaperTrail::Version.where(event: :update, item_type: "AgentRole", item_id: id).none? &&
        PaperTrail::Version.where(event: :destroy, item_type: "AgentRole", item_id: id).where("created_at < ?", @version.created_at).none?
    end
  end

  def agent_role_ids
    possible_parent_agent_role_versions.pluck(:item_id)
  end

  # TODO: voir s'il vaut mieux utiliser une méthode similaire à #versions_for_agent_roles_created_at_the_same_time
  # On ne vérifie pas que la création des access rights correspond effectivement à l'ajout à cette organisation, mais c'est peut-être pas grave ?
  def possible_parent_agent_role_versions
    PaperTrail::Version.where(event: :create, item_type: "AgentRole")
      .where("created_at < ?", @version.created_at)
      .where("object_changes->'agent_id'->1 = ?", @parent_agent.id.to_s).select do |version|
      organisation = Organisation.find_by(id: version.object_changes["organisation_id"].last)
      organisation&.territory_id = @version.territory_id && version.object_changes["access_level"]&.last == "admin"
    end
  end
end
