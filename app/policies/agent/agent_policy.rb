class Agent::AgentPolicy < ApplicationPolicy
  include CurrentAgentInPolicyConcern

  def current_agent_or_admin_in_record_organisation?
    record == current_agent || (
      record.roles.map(&:organisation_id) &
      current_agent.roles.level_admin.pluck(:organisation_id)
    ).any?
  end

  alias show? current_agent_or_admin_in_record_organisation?
  alias new? current_agent_or_admin_in_record_organisation?
  alias create? current_agent_or_admin_in_record_organisation?
  alias update? current_agent_or_admin_in_record_organisation?
  alias invite? current_agent_or_admin_in_record_organisation?
  alias rdvs? current_agent_or_admin_in_record_organisation?
  alias reinvite? current_agent_or_admin_in_record_organisation?
  alias destroy? current_agent_or_admin_in_record_organisation?

  class Scope < Scope
    include CurrentAgentInPolicyConcern

    def resolve
      scope_j = scope.joins(:organisations)
      if current_agent.service.secretariat?
        scope_j.where(organisations: { id: current_agent.organisation_ids })
      else
        current_agent.roles.map do |agent_role|
          if agent_role.can_access_others_planning?
            scope_j.where(organisations: { id: agent_role.organisation_id })
          else
            scope_j.where(organisations: { id: agent_role.organisation_id })
              .where(service: current_agent.service)
          end
        end.reduce(:or)
      end
    end
  end
end
