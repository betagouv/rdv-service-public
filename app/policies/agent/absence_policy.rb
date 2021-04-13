class Agent::AbsencePolicy < ApplicationPolicy
  include CurrentAgentInPolicyConcern

  def same_agent_or_has_access?
    agent_role_in_record_organisation.present? && (
      record.agent_id == current_agent.id ||
      (record.agent.services & current_agent.services).any? ||
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
      scope_a = scope.joins(agent: [:services])
      current_agent.roles.map do |agent_role|
        if agent_role.can_access_others_planning?
          scope_a.where(organisation_id: agent_role.organisation_id)
        else
          scope_a.where(organisation_id: agent_role.organisation_id)
            .where("services.id" => [current_agent.services.map(&:id)])
        end
      end.reduce(:or)
    end
  end
end
