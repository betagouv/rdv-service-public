class Agent::AgentAgendaPolicy < ApplicationPolicy
  include CurrentAgentInPolicyConcern

  def show?
    current_agent_role = current_agent.roles.find_by(organisation_id: record.organisation_id)
    other_agent_role = record.agent.roles.find_by(organisation_id: record.organisation_id)

    return false if current_agent_role.nil? || other_agent_role.nil?

    record.agent_id == current_agent.id ||
      record.agent.confrere_of?(current_agent) ||
      current_agent_role.can_access_others_planning?
  end
end
