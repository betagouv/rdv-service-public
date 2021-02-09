module Agent::SectorisationPolicyConcern
  extend ActiveSupport::Concern

  # agents can see all departement sectors but only edit those from orgas they
  # are admin in

  def index?
    admin_somewhere?
  end

  def show?
    admin_somewhere?
  end

  def destroy?
    admin?
  end

  def destroy_multiple?
    admin?
  end

  def edit?
    admin?
  end

  def update?
    admin?
  end

  def new?
    admin?
  end

  def create?
    admin?
  end

  protected

  def admin?
    context.agent.roles.in_departement(departement).any?(&:admin?)
  end
end
