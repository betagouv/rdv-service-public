class ProPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(organisation: pro.organisation)
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

  def invite?
    @pro.admin?
  end

  def reinvite?
    invite?
  end

  private

  def same_pro
    @pro == @record
  end
end
