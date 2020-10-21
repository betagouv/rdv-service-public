class Agent::ZonePolicy < DefaultAgentPolicy
  # agents can see all departement zones but only edit zones from orgas they
  # belong to

  def index?
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
    @context.agent.admin? && @context.agent.organisations.pluck(:departement).include?(@record.sector.departement)
  end

  class Scope < Scope
    def resolve
      departements = @context.agent.organisations.pluck(:departement).uniq
      scope.joins(:sectors).where(sectors: { departement: departements })
    end
  end
end
