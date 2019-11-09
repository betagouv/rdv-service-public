class Agent::OrganisationPolicy < DefaultAgentPolicy
  def destroy?
    false
  end

  class Scope < Scope
    def resolve
      scope.where(id: @context.agent.organisation_ids)
    end
  end
end
