# frozen_string_literal: true

class Configuration::AgentPolicy
  def initialize(context, agent)
    @context = context
    @agent = agent
  end

  def territorial_admin?
    @context.agent.territorial_admin_in?(@context.territory)
  end

  alias edit? territorial_admin?
  alias update? territorial_admin?

  class Scope
    def initialize(context, _scope)
      @context = context
    end

    def resolve
      Agent.where(roles: AgentRole.where(organisation: @context.territory.organisations))
    end
  end
end
