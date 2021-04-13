class Agent::AgentPolicy < ApplicationPolicy
  include CurrentAgentInPolicyConcern

  def current_agent_or_admin_in_record_organisation?
    record == current_agent || admin_in_record_organisation?
  end

  def admin_in_record_organisation?
    (
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

  def destroy?
    # Even admins cannot destroy themselves
    admin_in_record_organisation? && record != current_agent
  end

  class Scope < Scope
    include CurrentAgentInPolicyConcern

    def resolve
      scope_j = scope.joins(:organisations).joins(:services)
      if current_agent.secretariat?
        scope_j.where(organisations: { id: current_agent.organisation_ids })
      else
        (
          [scope_j.where(organisations: { id: current_agent.territorial_roles_organisation_ids })] +
          current_agent.roles.map do |agent_role|
            if agent_role.can_access_others_planning?
              scope_j.where(organisations: { id: agent_role.organisation_id })
            else
              scope_j.where(organisations: { id: agent_role.organisation_id })
                .where("services.id" => [current_agent.services.map(&:id)])
            end
          end
        ).reduce(:or)
      end
    end
  end
end
