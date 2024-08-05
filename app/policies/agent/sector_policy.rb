class Agent::SectorPolicy
  def initialize(agent, sector)
    @current_agent = agent
    @sector = sector
  end

  def territorial_admin?
    self.class.allowed_to_manage_sectors_in?(@sector.territory, @current_agent)
  end

  def self.allowed_to_manage_sectors_in?(territory, agent)
    agent.territorial_admin_in?(territory)
  end

  alias new? territorial_admin?
  alias create? territorial_admin?
  alias show? territorial_admin?
  alias edit? territorial_admin?
  alias update? territorial_admin?
  alias destroy? territorial_admin?

  class Scope
    def initialize(agent, scope)
      @current_agent = agent
      @scope = scope
    end

    def resolve
      @scope.where(territory_id: @current_agent.territorial_roles.select(:territory_id))
    end
  end
end
