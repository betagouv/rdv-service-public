class ProPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(organisation_id: pro.organisation_id)
    end
  end

  def index?
    @pro.admin?
  end

  def show?
    same_pro
  end

  def edit?
    same_pro
  end

  def destroy?
    same_pro || @pro.admin?
  end

  def invite?
    @pro.admin?
  end

  def reinvite?
    invite?
  end

  private

  def same_pro
    @pro == @record || @pro.admin?
  end
end
