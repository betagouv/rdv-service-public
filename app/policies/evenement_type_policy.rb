class EvenementTypePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(motif: pro.organisation.motifs)
    end
  end

  def index?
    @pro.admin?
  end

  def new?
    @pro.admin?
  end

  def create?
    admin_and_same_organisation?
  end

  def edit?
    admin_and_same_organisation?
  end

  def update?
    admin_and_same_organisation?
  end

  def destroy?
    admin_and_same_organisation?
  end

  private

  def admin_and_same_organisation?
    @pro.admin? && @record.motif.organisation == @pro.organisation
  end
end
