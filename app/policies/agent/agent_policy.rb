class Agent::AgentPolicy < Agent::AdminPolicy
  def new?
    admin_and_same_org?
  end

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
      if @context.organisation.nil?
        scope.joins(:organisations).where(organisations: { id: @context.agent.organisation_ids })
      elsif @context.can_access_others_planning?
        scope.joins(:organisations).where(organisations: { id: @context.organisation.id })
      else
        scope.joins(:organisations).where(organisations: { id: @context.organisation.id }, service_id: @context.agent.service_id)
      end
    end
  end
end
