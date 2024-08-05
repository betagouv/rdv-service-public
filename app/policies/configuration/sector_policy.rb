class Configuration::SectorPolicy
  def initialize(context, sector)
    @current_agent = context.agent
    @sector = sector
  end

  def territorial_admin?
    @current_agent.territorial_admin_in?(@sector.territory)
  end

  alias display? territorial_admin?
  alias new? territorial_admin?
  alias create? territorial_admin?
  alias show? territorial_admin?
  alias edit? territorial_admin?
  alias update? territorial_admin?
  alias destroy? territorial_admin?

  class Scope
    def initialize(context, _scope)
      @current_territory = context.territory
    end

    def resolve
      Sector.where(territory: @current_territory)
    end
  end
end
