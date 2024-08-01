class Agent::AgentRolePolicy
  class Scope < ApplicationPolicy::Scope
    include CurrentAgentInPolicyConcern

    def resolve
      my_roles = scope.merge(current_agent.roles)
      roles_of_orgs_i_admin = scope.where(organisation: current_agent.admin_orgs)

      my_roles.or roles_of_orgs_i_admin
    end
  end
end
