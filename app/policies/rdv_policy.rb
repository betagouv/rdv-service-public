class RdvPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      user_or_pro.rdvs
    end
  end

  def new?
    true
  end

  def status?
    true
  end

  def create?
    true
  end

  def show?
    true
  end

  def edit?
    true
  end

  def update?
    true
  end

  def destroy?
    true
  end
end
