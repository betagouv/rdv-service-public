class Agent::AdminPolicy < DefaultAgentPolicy
  def show?
    admin_and_same_org?
  end

  def create?
    admin_and_same_org?
  end

  def update?
    admin_and_same_org?
  end

  def destroy?
    admin_and_same_org?
  end

  class Scope < Scope
    def resolve
      scope.where(organisation_id: @context.organisation.id)
    end
  end
end
