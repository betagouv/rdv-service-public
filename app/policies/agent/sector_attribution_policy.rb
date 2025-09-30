class Agent::SectorAttributionPolicy
  def initialize(agent, sector_attribution)
    @current_agent = agent
    @sector_attribution = sector_attribution
  end

  def new?
    territorial_admin?
  end

  def create?
    territorial_admin? && organisation_belongs_to_territory? && agent_is_legit?
  end
  alias destroy? create?

  private

  def territorial_admin?
    @current_agent.territorial_admin_in?(@sector_attribution.sector.territory)
  end

  def organisation_belongs_to_territory?
    @sector_attribution.organisation.territory == @sector_attribution.sector.territory
  end

  def agent_is_legit?
    return true if @sector_attribution.agent.nil?

    @sector_attribution.agent.territories_through_organisations.include?(@sector_attribution.sector.territory)
  end
end
