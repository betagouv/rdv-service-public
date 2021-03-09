class Agent::SectorAttributionPolicy < DefaultAgentPolicy
  include Agent::SectorisationPolicyConcern

  protected

  def departement
    @record.sector.departement
  end

  class Scope < Scope
    def resolve
      departements = current_agent.organisations.pluck(:departement).uniq
      scope.joins(:sectors).where(sectors: { departement: departements })
    end
  end
end
