class Agent::OrganisationPolicy < DefaultAgentPolicy
  def link_to_organisation?
    @context.agent.organisation_ids.include?(@record.id)
  end

  def new?
    admin?
  end

  def create?
    admin?
  end

  def destroy?
    false
  end

  def users?
    admin?
  end

  def rdvs?
    admin?
  end

  class Scope < Scope
    def resolve
      scope.where(id: @context.agent.organisation_ids)
    end
  end
end
