class SuperAdmin::ComptePolicy < ApplicationPolicy
  def index?
    false
  end

  def create?
    true
  end

  alias new? create?
end
