class Agent::UserPolicy < DefaultAgentPolicy
  def show?
    same_org?
  end

  def create?
    same_org?
  end

  def invite?
    create?
  end

  def update?
    same_org?
  end

  def destroy?
    same_org?
  end

  class Scope < Scope
    def resolve
      scope.joins(:organisations).where(organisations: { id: @context.organisation.id })
    end
  end
end
