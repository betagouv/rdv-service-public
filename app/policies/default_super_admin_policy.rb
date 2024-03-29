class DefaultSuperAdminPolicy < ApplicationPolicy
  alias current_super_admin pundit_user
  delegate :support_member?, to: :current_super_admin
  delegate :legacy_admin_member?, to: :current_super_admin

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    false
  end

  def edit?
    false
  end

  def update?
    false
  end

  def destroy?
    false
  end

  def team_member?
    support_member? || legacy_admin_member?
  end

  class Scope < Scope
    def resolve
      # No filter for team members (for now)
      scope.all
    end
  end
end
