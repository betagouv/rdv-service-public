class MotifPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(organisation_id: pro.organisation_id)
    end
  end

  def index?
    @pro.admin?
  end

  def new?
    @pro.admin?
  end

  def create?
    @pro.admin?
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
    @pro.admin? && @record.organisation_id == @pro.organisation_id
  end
end
