class MotifPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(specialite: pro.organisation.specialites)
    end
  end

  def new?
    admin_and_belongs_to_specialite_organisation?
  end

  def create?
    admin_and_belongs_to_specialite_organisation?
  end

  def edit?
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
    @pro.admin? && @pro.organisation_id == @record.specialite.organisation_id
  end
end
