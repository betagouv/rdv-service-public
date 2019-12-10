class Agent::PlageOuverturePolicy < DefaultAgentPolicy
  class Scope < Scope
    def resolve
      if @context.agent.access_planning?
        scope.where(organisation_id: @context.organisation.id)
      else
        scope.where(organisation_id: @context.organisation.id, agent_id: @context.agent.id)
      end
    end
  end
end
