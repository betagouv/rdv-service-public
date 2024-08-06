class PrivilegeParentIdentifier
  def initialize(version)
    @privilege_creation_version = version
  end

  attr_reader :privilege_creation_version

  def parent_privilege?
    return true if privilege_creation_version.whodunnit.nil? # Si le whodunnit est nil, l'opération a été faite par un script

    return true if privilege_creation_version.whodunnit.start_with?("[Admin]")
    return true if privilege_creation_version.whodunnit.start_with?("[SuperAdmin]")

    agent = find_agent
    return false unless agent

    puts "Agent found"

    territory_id = privilege_creation_version.object_changes["territory_id"].last

    parent_territorial_role = AgentTerritorialRole.find_by(agent_id: agent.id, territory_id: territory_id)

    if parent_territorial_role
      puts "Parent role found"

      # Les versions sur cette table ont été ajoutées dans une pr du 27/6/2023 https://github.com/betagouv/rdv-service-public/pull/3579
      parent_territorial_role_created_at = parent_territorial_role.versions.where(event: :create)&.first&.created_at || Date.new(2023, 6, 27)

      if parent_territorial_role_created_at < privilege_creation_version.created_at
        true
      end
    end

    if version_has_no_territory_privilege? # On est en train de créer un access right, probablement pour ajouter l'agent à une organisation
      agent_roles = possible_parent_agent_roles(agent)
      return true if agent_roles.any? do |agent_role|
        create_version = agent_role.versions.find_by(event: :create)
        created_at = create_version&.created_at || Date.new(2023, 2, 16) # Date d'ajout des versions sur cette table
        created_at < version.created_at
      end
    end
  end

  def version_has_no_territory_privilege?
    privilege_creation_version.event == "create" && version.item_type == "AgentTerritorialAccessRight" && !access_right_changes?
  end

  def access_right_changes?
    (version.object_changes.keys & %w[
      allow_to_manage_access_rights
      allow_to_manage_teams
      allow_to_invite_agents
    ]).any? # array intersection
  end

  def possible_parent_agent_roles(parent_agent)
    organisation_ids = versions_for_agent_roles_created_at_the_same_time.map { |v| v.object_changes["organisation_id"].last }
    AgentRole.where(organisation_id: organisation_ids, agent: parent_agent)
  end

  def possible_parent_agent_roles_versions(parent_agent)
    PaperTrail::Version.where(event: :create, item_type: "AgentRole").where("object_changes->'agent_id'->1 = ?", parent_agent.id.to_s).last
  end

  def versions_for_agent_roles_created_at_the_same_time
    PaperTrail::Version.where(whodunnit: version.whodunnit, event: :create, item_type: "AgentRole")
      .where("created_at > ?", version.created_at - 1.second)
      .where("created_at < ?", version.created_at + 1)
  end

  def version
    privilege_creation_version
  end

  def find_agent
    agent_last_name = privilege_creation_version.whodunnit[/[A-Z][A-Z]+/]
    agent_first_name = privilege_creation_version.whodunnit.gsub(agent_last_name, "").gsub("[Agent]", "").strip

    agent = Agent.where("first_name ilike ?", agent_first_name).where("last_name ilike ?", agent_last_name).last

    if agent.nil?
      agent = Agent.find_by(first_name: agent_first_name, last_name: agent_last_name.capitalize)
    end

    nathalie = Agent.find 12622
    if privilege_creation_version.whodunnit[nathalie.full_name]
      agent = nathalie
    end

    agent
  end
end
