class Agent::MotifPolicy < Agent::AdminPolicy
  class Scope < Scope
    def resolve
      if @context.agent.can_access_others_planning?
        scope.where(organisation: @context.organisation)
      else
        scope.where(organisation: @context.organisation, service: @context.agent.service)
      end
    end
  end
end
