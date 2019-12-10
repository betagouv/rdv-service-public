class Agent::AgentPolicy < Agent::AdminPolicy
  def invite?
    create?
  end

  def show?
    @context.agent.access_planning? || @context.agent == @record
  end

  def reinvite?
    invite?
  end

  def destroy?
    same_agent_or_has_access?
  end

  class Scope < Scope
    def resolve
      scope.joins(:organisations).where(organisations: { id: @context.organisation.id })
    end
  end
end
