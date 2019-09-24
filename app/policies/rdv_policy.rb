class RdvPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user_or_pro.pro?
        scope.where(organisation_id: user_or_pro.organisation_id)
      elsif user_or_pro.user?
        user_or_pro.rdvs
      end
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
