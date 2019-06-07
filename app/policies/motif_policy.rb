class MotifPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(organisation_id: pro.organisation_id)
    end
  end

  def create?
    @pro.admin?
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
    @pro.admin? && @pro.organisation_id == @record.organisation_id
  end
end
