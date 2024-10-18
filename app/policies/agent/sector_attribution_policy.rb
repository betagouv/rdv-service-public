class Agent::SectorAttributionPolicy
  def initialize(agent, sector_attribution)
    @current_agent = agent
    @sector_attribution = sector_attribution
  end

  def territorial_admin?
    @current_agent.territorial_admin_in?(@sector_attribution.sector.territory)
  end

  alias new? territorial_admin?
  alias create? territorial_admin?
  alias destroy? territorial_admin?
end
