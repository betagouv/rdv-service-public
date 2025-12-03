class OperatorManager::TerritoryPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    record.operator == @pundit_user.operator
  end
end
