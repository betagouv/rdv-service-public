class Agent::SectorPolicy < DefaultAgentPolicy
  # agents can see all departement sectors but only edit zones from orgas they
  # belong to

  def index?
    @context.agent.admin?
  end

  def show?
    @context.agent.admin?
  end

  def destroy?
    orga_admin?
  end

  def destroy_multiple?
    orga_admin?
  end

  def edit?
    orga_admin?
  end

  def update?
    orga_admin?
  end

  def create?
    orga_admin?
  end

  private

  def orga_admin?
    @context.agent.admin? && @context.agent.organisations.pluck(:departement).include?(@record.departement)
  end

  class Scope < Scope
    def resolve
      departements = @context.agent.organisations.pluck(:departement).uniq
      scope.where(departement: departements)
    end
  end
end
