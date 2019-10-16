class PlageOuverturePolicy < ApplicationPolicy
  def create?
    record_belongs_to_agent?
  end

  def update?
    record_belongs_to_agent?
  end

  def destroy?
    record_belongs_to_agent?
  end
end
