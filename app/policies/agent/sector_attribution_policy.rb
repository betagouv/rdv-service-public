class Agent::SectorAttributionPolicy < DefaultAgentPolicy
  def create?
    orga_admin?
  end

  def destroy?
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
