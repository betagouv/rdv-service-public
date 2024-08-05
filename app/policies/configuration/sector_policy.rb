class Configuration::SectorPolicy
  def initialize(context, sector)
    @current_agent = context.agent
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
    def initialize(context, scope)
      @current_agent = context.agent
      @scope = scope
    end

    def resolve
      @scope.where(territory_id: @current_agent.territorial_roles.pluck(:territory_id))
    end
  end
end
