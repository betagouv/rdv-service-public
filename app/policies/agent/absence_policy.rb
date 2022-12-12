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
  alias versions? same_agent_or_has_access?

  private

  def agent_role_in_record_organisation
    @agent_role_in_record_organisation ||= \
      current_agent.roles.find_by(organisation_id: record.organisation_id)
  end

  class Scope < Scope
    include CurrentAgentInPolicyConcern

    def resolve
      if current_agent.service.secretariat?
        scope.where(organisation: current_agent.organisations)
      else
        absences_of_orgs_i_admin = scope.where(organisation: current_agent.organisations_level(:admin))

        absences_of_orgs_i_basic_same_service = scope.where(organisation: current_agent.organisations_level(:basic))
          .joins(:agent).where(agents: { service: current_agent.service })
        absences_of_orgs_i_basic_same_service = scope.where(id: absences_of_orgs_i_basic_same_service)

        scope.where_id_in_subqueries([absences_of_orgs_i_admin, absences_of_orgs_i_basic_same_service])
      end
    end
  end
end
