class RdvPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if @user_or_agent.agent?
        @scope.where(organisation_id: @user_or_agent.organisation_ids)
      elsif @user_or_agent.user?
        @user_or_agent.rdvs
      end
    end
  end

  def new?
    if @user_or_agent.agent?
      true
    elsif @user_or_agent.user?
      @record.users.include?(@user_or_agent)
    end
  end

  def status?
    true
  end

  def create?
    if @user_or_agent.agent?
      true
    elsif @user_or_agent.user?
      @record.users.include?(@user_or_agent)
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
    @user_or_agent.user? && @record.users.include?(@user_or_agent)
  end
end
