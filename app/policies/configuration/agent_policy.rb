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
  alias show? territorial_admin?
  alias update? territorial_admin?
end
