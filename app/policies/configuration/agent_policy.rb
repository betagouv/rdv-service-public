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

  def show?
    @agent.organisations.flat_map(&:territory).include?(@context.territory) &&
      (@agent.service == @context.agent.service || territorial_admin?)
  end
end
