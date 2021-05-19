# frozen_string_literal: true

class Agent::AbsencePolicy < ApplicationPolicy
  include CurrentAgentInPolicyConcern

  def same_agent_or_has_access?
    agent_role_in_record_organisation.present? && (
      record.agent_id == current_agent.id ||
      record.agent.service_id == current_agent.service_id ||
      agent_role_in_record_organisation.can_access_others_planning?
    )
  end

  alias show? same_agent_or_has_access?
  alias create? same_agent_or_has_access?
  alias cancel? same_agent_or_has_access?
  alias new? same_agent_or_has_access?
  alias update? same_agent_or_has_access?
  alias edit? same_agent_or_has_access?
  alias destroy? same_agent_or_has_access?

  private

  def agent_role_in_record_organisation
    @agent_role_in_record_organisation ||= \
      current_agent.roles.find_by(organisation_id: record.organisation_id)
  end

  class Scope < Scope
    include CurrentAgentInPolicyConcern

    def resolve
      current_agent.roles.map do |agent_role|
        if agent_role.can_access_others_planning?
          scope.joins(:agent).where(organisation_id: agent_role.organisation_id)
        else
          scope.joins(:agent).where(organisation_id: agent_role.organisation_id)
            .where(agents: { service: current_agent.service })
        end
      end.reduce(:or)
    end
  end
end
