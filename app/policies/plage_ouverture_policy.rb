class PlageOuverturePolicy < ApplicationPolicy
  def create?
    record_belongs_to_pro?
  end

  def update?
    record_belongs_to_pro?
  end

  def destroy?
    record_belongs_to_pro?
  end
end
