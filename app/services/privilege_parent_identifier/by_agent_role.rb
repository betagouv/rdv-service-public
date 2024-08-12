class PrivilegeParentIdentifier::ByAgentRole
  def initialize(version, parent_agent)
    @version = version
    @parent_agent = parent_agent
  end

  def identified?
    return unless @version.no_territory_privilege? # On est en train de créer un access right, probablement pour ajouter l'agent à une organisation

    agent_roles = possible_parent_agent_roles

    # TODO: vérifier que ça marche pour les versions d'agent roles plutot que juste pour les access rights
    agent_roles.select do |agent_role|
      create_version = agent_role.versions.find_by(event: :create)
      created_at = create_version&.created_at || Date.new(2023, 2, 16) # Date d'ajout des versions sur cette table
      created_at < @version.created_at
    end.any? do |agent_role|
      agent_role.paper_trail.version_at(@version.created_at).access_level.to_s == "admin"
    end
  end

  def possible_parent_agent_roles
    organisation_ids = versions_for_agent_roles_created_at_the_same_time.map { |v| v.object_changes["organisation_id"].last }
    AgentRole.where(organisation_id: organisation_ids, agent: @parent_agent, access_level: :admin)
  end

  def versions_for_agent_roles_created_at_the_same_time
    PaperTrail::Version.where(whodunnit: @version.whodunnit, event: :create, item_type: "AgentRole")
      .where("created_at > ?", @version.created_at - 1.second)
      .where("created_at < ?", @version.created_at + 1)
  end
end
