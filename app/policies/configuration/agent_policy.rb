# frozen_string_literal: true

class Configuration::AgentPolicy
  def initialize(context, agent)
    @current_agent = context.agent
    @current_territory = context.territory
    @agent = agent
  end

  def territorial_admin?
    @current_agent.territorial_admin_in?(@current_territory)
  end

  alias edit? territorial_admin?
  alias update? territorial_admin?

  class Scope
    def initialize(context, _scope)
      @current_territory = context.territory
    end

    def resolve
      Agent.where(roles: AgentRole.where(organisation: @current_territory.organisations))
    end
  end
end
