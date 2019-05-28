class ProPolicy < ApplicationPolicy
  
  def show?
    true
  end

  def index?
    true if current_pro.admin?
  end
  
end