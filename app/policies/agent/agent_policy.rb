class Agent::AgentPolicy < Agent::AdminPolicy
  def invite?
    create?
  end

  def reinvite?
    invite?
  end

  def destroy?
    same_agent_or_admin?
  end

  class Scope < Scope
    def resolve
      scope.joins(:organisations).where(organisations: { id: @context.organisation.id })
    end
  end
end
