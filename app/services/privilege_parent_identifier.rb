class PrivilegeParentIdentifier
  def initialize(version)
    @version = PrivilegeParentIdentifier::PrivilegeVersion.new(version)
  end

  attr_reader :version

  def parent_privilege?
    return true if version.whodunnit.nil? # Si le whodunnit est nil, l'opération a été faite par un script

    return true if version.whodunnit.start_with?("[Admin]")
    return true if version.whodunnit.start_with?("[SuperAdmin]")

    agents = find_agents

    agents.each do |agent|
      Rails.logger.info "Agent found"

      return true if PrivilegeParentIdentifier::ByAgentTerritorialRole.new(version, agent).identified?
      return true if PrivilegeParentIdentifier::ByTerritorialRoleVersion.new(version, agent).identified?

      return true if PrivilegeParentIdentifier::ByAccessRightVersion.new(version, agent).identified?

      return true if PrivilegeParentIdentifier::ByAgentRole.new(version, agent).identified?
      return true if PrivilegeParentIdentifier::ByAgentRoleVersion.new(version, agent).identified?
      return true if PrivilegeParentIdentifier::ByDeletedAgentRoleVersion.new(version, agent).identified?
    end

    false
  end

  def find_agents
    agent_last_name = version.whodunnit[/[A-ZÉ][A-ZÉ].*$/]
    agent_first_name = version.whodunnit.gsub(agent_last_name, "").gsub("[Agent]", "").strip

    if version.whodunnit == "[Agent] #{agent_last_name}" # ce if gère le cas d'un last name mal parsé par la regex au dessus
      agent_first_name = agent_last_name.split.first
      agent_last_name = agent_last_name.split.last
    end

    agents = Agent.where("first_name ilike ?", agent_first_name).where("last_name ilike ?", agent_last_name)

    agents += Agent.where("first_name ilike ?", agent_first_name).where("last_name ilike ?", agent_last_name.capitalize)

    whodunnit_full_name = version.whodunnit.gsub("[Agent]", "").strip
    agents += Agent.search_by_text(agent_last_name).to_a.select do |agent|
      agent.full_name == whodunnit_full_name
    end

    agents.uniq
  end
end
