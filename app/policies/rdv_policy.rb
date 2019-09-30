class RdvPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      user_or_pro.rdvs
    end
  end

  def new?
    if @user_or_pro.pro?
      true
    elsif @user_or_pro.user?
      @record.users.include?(@user_or_pro)
    end
  end

  def status?
    true
  end

  def create?
    if @user_or_pro.pro?
      true
    elsif @user_or_pro.user?
      @record.users.include?(@user_or_pro)
    end
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

  def confirmation?
    @user_or_pro.user? && @record.users.include?(@user_or_pro)
  end
end
