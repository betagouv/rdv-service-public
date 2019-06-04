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
    same_pro_or_admin?
  end

  def edit?
    same_pro_or_admin?
  end

  def invite?
    @pro.admin?
  end

  def reinvite?
    invite?
  end

  private

  def same_pro_or_admin?
    @pro == @record || @pro.admin?
  end
end
