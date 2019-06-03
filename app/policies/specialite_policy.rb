class SpecialitePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(organisation: pro.organisation)
    end
  end

  def index?
    @pro.admin?
  end

  def show?
    admin_and_belongs_to_specialite_organisation?
  end

  def new?
    @pro.admin?
  end

  def edit?
    admin_and_belongs_to_specialite_organisation?
  end

  def create?
    admin_and_belongs_to_specialite_organisation?
  end

  def update?
    admin_and_belongs_to_specialite_organisation?
  end

  def destroy?
    admin_and_belongs_to_specialite_organisation?
  end

  private

  def admin_and_belongs_to_specialite_organisation?
    @pro.admin? && @pro.organisation_id == @record.organisation_id
  end
end
