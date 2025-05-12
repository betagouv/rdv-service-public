class Agent::TerritoryCreationRequestPolicy
  def initialize(current_agent, territory_creation_request)
    @current_agent = current_agent
    @territory_creation_request = territory_creation_request
  end

  def new?
    @current_agent.agent_territorial_access_rights.none? && @current_agent.territory_creation_request.blank?
  end
  alias create? new?
end
