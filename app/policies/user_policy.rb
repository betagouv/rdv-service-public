class UserPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(organisation: pro.organisation)
    end
  end

  def index?
    true
  end

  def show?
    true
  end

  def create?
    true
  end

  def edit?
    same_organisation
  end

  def update?
    same_organisation
  end

  def destroy?
    same_organisation && @pro.admin?
  end

  private

  def same_organisation
    @record.organisation == @pro.organisation
  end
end
