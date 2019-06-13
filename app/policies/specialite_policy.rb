class SpecialitePolicy < ApplicationPolicy
  def index?
    @pro.admin?
  end

  def show?
    @pro.admin?
  end
end
