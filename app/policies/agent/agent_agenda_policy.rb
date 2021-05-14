# frozen_string_literal: true

class Agent::AgentAgendaPolicy < ApplicationPolicy
  include CurrentAgentInPolicyConcern

  def show?
    agent_role_in_record_organisation.present? && (
      record.agent_id == current_agent.id ||
      record.agent.service_id == current_agent.service_id ||
      agent_role_in_record_organisation.can_access_others_planning?
    )
  end

  private

  def agent_role_in_record_organisation
    @agent_role_in_record_organisation ||= \
      current_agent.roles.find_by(organisation_id: record.organisation_id)
  end
end
