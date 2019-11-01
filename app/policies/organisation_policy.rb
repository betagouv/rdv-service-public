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
      @user_or_agent.agent? ? scope.joins(:agents).where(agents: { id: @user_or_agent.id }) : scope.none
    end
  end
end
