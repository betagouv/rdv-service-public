class Agent::AbsencePolicy < DefaultAgentPolicy
  class Scope < Scope
    def resolve
      if current_organisation.present?
        scope_down_absences(scope, current_organisation.id, current_agent_role)
      else
        current_agent.roles.map do |agent_role|
          scope_down_absences(scope, agent_role.organisation_id, agent_role)
        end.reduce(:or)
      end
    end

    def scope_down_absences(scope, organisation_id, agent_role)
      new_scope = scope.where(organisation_id: organisation_id)
      new_scope = new_scope.joins(:agent).where(agents: { service: current_agent.service }) \
        unless agent_role.can_access_others_planning?
      new_scope
    end
  end
end
