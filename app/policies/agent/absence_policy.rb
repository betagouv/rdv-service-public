class Agent::AbsencePolicy < DefaultAgentPolicy
  class Scope < Scope
    def resolve
      if @context.organisation.present?
        scope_down_absences(scope, @context.organisation.id, @context.agent_role)
      else
        @context.agent.roles.map do |agent_role|
          scope_down_absences(scope, agent_role.organisation_id, agent_role)
        end.reduce(:or)
      end
    end

    def scope_down_absences(scope, organisation_id, agent_role)
      new_scope = scope.where(organisation_id: organisation_id)
      new_scope = new_scope.joins(:agent).where(agents: { service: @context.agent.service }) \
        unless agent_role.can_access_others_planning?
      new_scope
    end
  end
end
