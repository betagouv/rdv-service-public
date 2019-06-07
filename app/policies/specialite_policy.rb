class SpecialitePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def index?
    @pro.admin?
  end

  def show?
    @pro.admin?
  end
end
