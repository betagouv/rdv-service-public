class SuperAdmin::ComptePolicy < ApplicationPolicy
  def index?
    true
  end

  def create?
    true
  end

  alias new? create?
end
