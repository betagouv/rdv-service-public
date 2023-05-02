# frozen_string_literal: true

class Agent::AgentRolePolicy < ApplicationPolicy
  include CurrentAgentInPolicyConcern

  def current_agent_admin_in_record_organisation?
    agent_role_in_record_organisation&.admin?
  end

  alias create? current_agent_admin_in_record_organisation?
  alias edit? current_agent_admin_in_record_organisation?
  alias update? current_agent_admin_in_record_organisation?

  private

  def agent_role_in_record_organisation
    @agent_role_in_record_organisation ||= \
      current_agent.roles.find_by(organisation_id: record.organisation_id)
  end

  class Scope < Scope
    include CurrentAgentInPolicyConcern

    def resolve
      my_roles = scope.merge(current_agent.roles)
      roles_of_orgs_i_admin = scope.where(organisation: current_agent.admin_orgs)

      my_roles.or roles_of_orgs_i_admin
    end
  end
end
