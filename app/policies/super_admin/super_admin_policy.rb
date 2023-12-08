class SuperAdmin::SuperAdminPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  # TODO : Disable create, new, edit, update, destroy for SuperAdmin Policy.
  # This is critical for security and has to be done by a dev
  def create?
    true
  end

  def new?
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

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end
