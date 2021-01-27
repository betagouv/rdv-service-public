class Agent::MotifPolicy < Agent::AdminPolicy
  def show?
    admin_and_same_org? || same_agent_or_has_access?
  end

  class Scope < Scope
    def resolve
      if @context.can_access_others_planning?
        scope.where(organisation: @context.organisation)
      else
        scope.where(organisation: @context.organisation, service: @context.agent.service)
      end
    end
  end
end
