class Agent::SectorPolicy
  def initialize(agent, sector)
    @current_agent = agent
    @sector = sector
  end

  def allowed_to_manage_sectors?
    self.class.allowed_to_manage_sectors_in?(@sector.territory, @current_agent)
  end

  def self.allowed_to_manage_sectors_in?(territory, agent)
    agent.territorial_admin_in?(territory)
  end

  alias new? allowed_to_manage_sectors?
  alias create? allowed_to_manage_sectors?
  alias show? allowed_to_manage_sectors?
  alias edit? allowed_to_manage_sectors?
  alias update? allowed_to_manage_sectors?
  alias destroy? allowed_to_manage_sectors?

  class Scope
    def initialize(agent, scope)
      @current_agent = agent
      @scope = scope
    end

    def resolve
      @scope.where(territory_id: @current_agent.agent_territorial_access_rights.where(territory_admin: true).select(:territory_id))
    end
  end
end
