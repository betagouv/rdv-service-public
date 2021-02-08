class Agent::SectorPolicy < DefaultAgentPolicy
  include Agent::SectorisationPolicyConcern

  protected

  def departement
    @record.departement
  end

  class Scope < Scope
    def resolve
      departements = context.agent.organisations.pluck(:departement).uniq
      scope.where(departement: departements)
    end
  end
end
