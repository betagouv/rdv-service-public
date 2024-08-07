class PrivilegeParentIdentifier
  def initialize(version)
    @privilege_creation_version = PrivilegeParentIdentifier::PrivilegeVersion.new(version)
  end

  attr_reader :privilege_creation_version

  def parent_privilege?
    return true if privilege_creation_version.whodunnit.nil? # Si le whodunnit est nil, l'opération a été faite par un script

    return true if privilege_creation_version.whodunnit.start_with?("[Admin]")
    return true if privilege_creation_version.whodunnit.start_with?("[SuperAdmin]")

    agents = find_agents
    return false unless agents.any?

    agents.each do |agent|
      puts "Agent found"

      territory_id = version.territory_id

      parent_territorial_role = AgentTerritorialRole.find_by(agent_id: agent.id, territory_id: territory_id)

      if parent_territorial_role
        puts "Parent role found"

        # Les versions sur cette table ont été ajoutées dans une pr du 27/6/2023 https://github.com/betagouv/rdv-service-public/pull/3579
        parent_territorial_role_created_at = parent_territorial_role.versions.where(event: :create)&.first&.created_at || Date.new(2023, 6, 27)

        if parent_territorial_role_created_at < privilege_creation_version.created_at
          return true
        end
      end

      # Jusqu'à https://github.com/betagouv/rdv-service-public/pull/4524/files, le droit allow_to_manage_access_rights suffisait pour créer un admin de territoire
      parent_territorial_access_rights = AgentTerritorialAccessRight.where("created_at < ?", version.created_at)
        .where(allow_to_manage_access_rights: true).find_by(agent_id: agent.id, territory_id: territory_id)

      if parent_territorial_access_rights
        return true
      end

      if version_has_no_territory_privilege? # On est en train de créer un access right, probablement pour ajouter l'agent à une organisation
        agent_roles = possible_parent_agent_roles(agent)
        return true if agent_roles.any? do |agent_role|
          create_version = agent_role.versions.find_by(event: :create)
          created_at = create_version&.created_at || Date.new(2023, 2, 16) # Date d'ajout des versions sur cette table
          created_at < version.created_at
        end
      end

      return true if PrivilegeParentIdentifier::ByAccessRightVersion.new(version, agent).identified?
      return true if PrivilegeParentIdentifier::ByAgentRoleVersion.new(version, agent).identified?
      return true if PrivilegeParentIdentifier::ByTerritorialRoleVersion.new(version, agent).identified?
    end

    false
  end

  def version_has_no_territory_privilege?
    version.no_territory_privilege?
  end

  def possible_parent_agent_roles(parent_agent)
    organisation_ids = versions_for_agent_roles_created_at_the_same_time.map { |v| v.object_changes["organisation_id"].last }
    AgentRole.where(organisation_id: organisation_ids, agent: parent_agent)
  end

  def versions_for_agent_roles_created_at_the_same_time
    PaperTrail::Version.where(whodunnit: version.whodunnit, event: :create, item_type: "AgentRole")
      .where("created_at > ?", version.created_at - 1.second)
      .where("created_at < ?", version.created_at + 1)
  end

  def version
    privilege_creation_version
  end

  def find_agents
    agent_last_name = privilege_creation_version.whodunnit[/[A-ZÉ][A-ZÉ].*$/]
    agent_first_name = privilege_creation_version.whodunnit.gsub(agent_last_name, "").gsub("[Agent]", "").strip

    if version.whodunnit == "[Agent] #{agent_last_name}"
      agent_first_name = agent_last_name.split(" ").first
      agent_last_name = agent_last_name.split(" ").last
    end

    agents = Agent.where("first_name ilike ?", agent_first_name).where("last_name ilike ?", agent_last_name)

    agents += Agent.where("first_name ilike ?", agent_first_name).where("last_name ilike ?", agent_last_name.capitalize)

    whodunnit_full_name = privilege_creation_version.whodunnit.gsub("[Agent]", "").strip
    agents += Agent.search_by_text(agent_last_name).to_a.select do |agent|
      agent.full_name == whodunnit_full_name
    end

    agents
  end
end
