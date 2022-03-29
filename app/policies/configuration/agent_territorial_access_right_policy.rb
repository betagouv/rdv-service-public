# frozen_string_literal: true

class Configuration::AgentTerritorialAccessRightPolicy
  def initialize(context, agent_territorial_access_right)
    @current_agent = context.agent
    @current_territory = context.territory
    @agent_territorial_access_right = agent_territorial_access_right
  end

  def update?
    @current_agent.territorial_admin_in?(@agent_territorial_access_right.territory)
  end
end
