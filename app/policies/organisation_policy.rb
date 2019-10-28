class OrganisationPolicy < AdminPolicy
  def destroy?
    false
  end

  class Scope
    attr_reader :user_or_agent, :scope

    def initialize(user_or_agent, scope)
      @user_or_agent = user_or_agent
      @scope = scope
    end

    def resolve
      @user_or_agent.agent? && @user_or_agent.admin? ? scope.where(id: @user_or_agent.organisation_ids) : []
    end
  end
end
