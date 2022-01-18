# frozen_string_literal: true

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
  alias versions? current_agent_or_admin_in_record_organisation?
  alias export? current_agent_or_admin_in_record_organisation?

  def destroy?
    # Even admins cannot destroy themselves
    admin_in_record_organisation? && record != current_agent
  end

  class Scope < Scope
    include CurrentAgentInPolicyConcern

    def resolve
      if current_agent.service.secretariat?
        scope.joins(:organisations).merge(current_agent.organisations)
      else
        agents_of_territories_i_admin = scope.joins(:organisations).merge(current_agent.organisations_of_territorial_roles)

        agents_of_orgs_i_admin = scope.joins(:organisations).merge(current_agent.organisations_level(:admin))

        agents_of_orgs_i_basic_same_service = scope.joins(:organisations).merge(current_agent.organisations_level(:basic))
          .where(service: current_agent.service)

        # wrap in subqueries so that we can OR without worrying about “structural compatibility”
        # (i.e. the joined tables are not the same)
        scope.where(id: agents_of_territories_i_admin)
          .or(scope.where(id: agents_of_orgs_i_admin))
          .or(scope.where(id: agents_of_orgs_i_basic_same_service))
      end
    end
  end
end
