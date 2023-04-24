# frozen_string_literal: true

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
  alias toggle_displays? current_agent?

  def destroy?
    # Even admins cannot destroy themselves
    admin_in_record_organisation? && record != current_agent
  end

  def rdvs_users_export?
    current_territory = context&.organisation&.territory
    access_rights = current_agent.access_rights_for_territory(current_territory)
    access_rights&.allow_to_download_metrics?
  end

  class Scope < Scope
    include CurrentAgentInPolicyConcern

    def resolve
      if current_agent.service.secretariat?
        scope.where(id: AgentRole.where(organisation_id: current_agent.organisations).select(:agent_id))
      else
        agents_of_territories_i_admin = scope.joins(:organisations).merge(current_agent.organisations_of_territorial_roles)

        agents_of_orgs_i_admin = scope.joins(:organisations).merge(current_agent.admin_orgs)

        agents_of_orgs_i_basic_same_service = scope.joins(:organisations).merge(current_agent.basic_orgs)
          .where(service: current_agent.service)

        scope.where_id_in_subqueries([agents_of_territories_i_admin, agents_of_orgs_i_admin, agents_of_orgs_i_basic_same_service])
      end
    end
  end
end
