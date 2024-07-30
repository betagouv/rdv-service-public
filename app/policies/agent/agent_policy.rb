class Agent::AgentPolicy < ApplicationPolicy
  include CurrentAgentInPolicyConcern

  def current_agent_or_admin_in_record_organisation?
    current_agent? || admin_in_record_organisation?
  end

  def current_agent?
    record == current_agent
  end

  def admin_in_record_organisation?
    (
      record.roles.map(&:organisation_id) &
      current_agent.roles.access_level_admin.pluck(:organisation_id)
    ).any?
  end

  alias show? current_agent_or_admin_in_record_organisation?
  alias new? current_agent_or_admin_in_record_organisation?
  alias create? current_agent_or_admin_in_record_organisation?
  alias edit? current_agent_or_admin_in_record_organisation?
  alias update? current_agent_or_admin_in_record_organisation?
  alias invite? current_agent_or_admin_in_record_organisation?
  alias rdvs? current_agent_or_admin_in_record_organisation?
  alias reinvite? current_agent_or_admin_in_record_organisation?
  alias versions? current_agent_or_admin_in_record_organisation?
  alias toggle_displays? current_agent?

  def destroy?
    # Even admins cannot destroy themselves
    admin_in_record_organisation? && record != current_agent
  end

  class Scope < Scope
    include CurrentAgentInPolicyConcern

    def resolve
      scope = scope.joins(:organisations) # JOINing on :organisations allows us to #merge Organisation scopes

      agents_i_can_see_as_secretaire = current_agent.secretaire? ? scope.merge(current_agent.organisations) : scope.none
      agents_of_territories_i_admin = scope.merge(current_agent.organisations_of_territorial_roles)
      agents_of_orgs_i_admin = scope.merge(current_agent.admin_orgs)
      agents_of_orgs_i_basic_same_service = scope.merge(current_agent.basic_orgs).merge(current_agent.confreres)

      scope.where_id_in_subqueries([agents_i_can_see_as_secretaire, agents_of_territories_i_admin, agents_of_orgs_i_admin, agents_of_orgs_i_basic_same_service])
    end
  end
end
