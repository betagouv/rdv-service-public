class UserPolicy < ApplicationPolicy
  def show?
    agent_and_belongs_to_record_organisation?
  end

  def create?
    agent_and_belongs_to_record_organisation?
  end

  def link_to_organisation?
    @user_or_agent.agent?
  end

  def invite?
    @user_or_agent.agent?
  end

  def update?
    if @user_or_agent.agent?
      agent_and_belongs_to_record_organisation?
    elsif @user_or_agent.user?
      @record.id == @user_or_agent.id
    end
  end

  def destroy?
    agent_and_belongs_to_record_organisation?
  end

  class Scope
    attr_reader :user_or_agent, :scope

    def initialize(user_or_agent, scope)
      @user_or_agent = user_or_agent
      @scope = scope
    end

    def resolve
      @user_or_agent.agent? ? scope.all : scope.none
    end
  end
end
