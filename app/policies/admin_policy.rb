class AdminPolicy < ApplicationPolicy
  def show?
    agent_and_admin?
  end

  def create?
    agent_and_admin?
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
      agent_and_admin? && @user_or_agent.organisation_ids.include?(@record.id)
    else
      agent_and_admin? && @user_or_agent.organisation_ids.include?(@record.organisation_id)
    end
  end

  class Scope
    attr_reader :user_or_agent, :scope

    def initialize(user_or_agent, scope)
      @user_or_agent = user_or_agent
      @scope = scope
    end

    def resolve
      @user_or_agent.agent? ? scope.where(organisation_id: @user_or_agent.organisation_ids) : []
    end
  end
end
