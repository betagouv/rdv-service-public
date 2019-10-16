class AdminPolicy < ApplicationPolicy
  def show?
    agent_and_admin?
  end

  def new?
    agent_and_admin?
  end

  def create?
    agent_and_admin?
  end

  def edit?
    admin_and_belongs_to_record_organisation?
  end

  def update?
    admin_and_belongs_to_record_organisation?
  end

  def destroy?
    admin_and_belongs_to_record_organisation?
  end

  def agent_and_admin?
    @user_or_agent.agent? && @user_or_agent.admin?
  end

  def admin_and_belongs_to_record_organisation?
    if @record.is_a? Organisation
      agent_and_admin? && @user_or_agent.organisation_id == @record.id
    else
      agent_and_admin? && @user_or_agent.organisation_id == @record.organisation_id
    end
  end

  class Scope
    attr_reader :user_or_agent, :scope

    def initialize(user_or_agent, scope)
      @user_or_agent = user_or_agent
      @scope = scope
    end

    def agent_and_admin?
      @user_or_agent.agent? && @user_or_agent.admin?
    end

    def resolve
      agent_and_admin? ? scope.where(organisation_id: @user_or_agent.organisation_id) : []
    end
  end
end
