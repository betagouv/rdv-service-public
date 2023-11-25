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

  def versions?
    admin_and_same_org?
  end

  class Scope < Scope
    def resolve
      scope.where(organisation_id: current_organisation.id)
    end
  end
end
