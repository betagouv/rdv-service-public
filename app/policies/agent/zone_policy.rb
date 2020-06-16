class Agent::ZonePolicy < DefaultAgentPolicy
  # agents can see all departement zones but only edit zones from orgas they
  # belong to

  def index?
    @context.agent.admin_departement?
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

  def create?
    orga_admin?
  end

  private

  def orga_admin?
    @context.agent.admin_departement? && @context.agent.organisation_ids.include?(@record.organisation_id)
  end

  class Scope < Scope
    def resolve
      departements = @context.agent.organisations.pluck(:departement).uniq
      orgas = Organisation.where(departement: departements)
      scope.where(organisation_id: orgas.pluck(:id))
    end
  end
end
