class Agent::AbsencePolicy < DefaultAgentPolicy
  class Scope < Scope
    def resolve
      if @context.agent.can_access_others_planning?
        scope.where(organisation_id: @context.organisation.id)
      else
        scope.joins(:agent).where(organisation_id: @context.organisation.id, agents: { service_id: @context.agent.service_id })
      end
    end
  end
end
