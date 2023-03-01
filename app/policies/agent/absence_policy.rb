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
      current_agent.roles.find_by(organisation_id: record.agent.organisations)
  end

  class Scope < Scope
    include CurrentAgentInPolicyConcern

    def resolve
      if current_agent.service.secretariat?
        scope.where(agent: Agent.where(organisations: current_agent.organisations))
      else
        my_admin_orgs = current_agent.organisations_level(:admin)
        agents_in_my_admin_orgs = Agent.in_orgs(my_admin_orgs)

        my_basic_orgs = current_agent.organisations_level(:basic)
        agents_in_my_basic_orgs = Agent.in_orgs(my_basic_orgs)
        agents_in_my_basic_orgs_with_same_service = agents_in_my_basic_orgs.where(service: current_agent.service)

        scope.where(agent: agents_in_my_admin_orgs + agents_in_my_basic_orgs_with_same_service)
      end
    end
  end
end
