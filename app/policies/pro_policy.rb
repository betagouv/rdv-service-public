class ProPolicy < ApplicationPolicy
  def show?
    same_pro
  end

  def edit?
    same_pro
  end

  private

  def same_pro
    @current_pro == @user
  end
end
