class Agent::AgentPolicy < Agent::AdminPolicy
  def invite?
    create?
  end

  def show?
    same_agent_or_has_access?
  end

  def rdvs?
    same_agent_or_has_access?
  end

  def reinvite?
    invite?
  end

  def destroy?
    same_agent_or_has_access?
  end

  class Scope < Scope
    def resolve
      if @context.agent.can_access_others_planning?
        scope.joins(:organisations).where(organisations: { id: @context.organisation.id })
      else
        scope.joins(:organisations).where(organisations: { id: @context.organisation.id }, service_id: @context.agent.service_id)
      end
    end
  end
end
