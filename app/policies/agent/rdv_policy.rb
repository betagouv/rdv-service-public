class Agent::RdvPolicy < DefaultAgentPolicy
  def status?
    same_agent_or_admin?
  end

  class Scope < Scope
    def resolve
      if @context.agent.admin?
        scope.where(organisation_id: @context.organisation.id)
      else
        scope.joins(:agents).where(organisation_id: @context.organisation.id, agents: { id: @context.agent.id })
      end
    end
  end
end
