class Agent::OrganisationPolicy < DefaultAgentPolicy
  def link_to_organisation?
    @context.agent.organisation_ids.include?(@record.id)
  end

  def destroy?
    false
  end

  class Scope < Scope
    def resolve
      scope.where(id: @context.agent.organisation_ids)
    end
  end
end
